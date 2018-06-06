from warnings import catch_warnings, simplefilter
from os import chdir
from sys import argv
from iris import FUTURE, load_cube, Constraint
from iris.analysis import MEAN
from iris.time import PartialDateTime
from seaborn import plt
import seaborn as sns

sns.set_style('whitegrid', {'font.sans-serif': "Helvetica"})
sns.set_palette(sns.color_palette('Set1'))

def extract_error(field, dirname):
    analys = load_cube(f'{dirname}/anal_mean.nc', field)
    nature = load_cube('nature.nc', field)

    # Get minimum duration of data
    time = min(analys.coord('time').cell(-1), nature.coord('time').cell(-1))
    analys = analys.extract(Constraint(time=lambda t: t < time))
    nature = nature.extract(Constraint(time=lambda t: t < time))

    # Compute time mean after March 1st 00:00
    analys = analys.extract(Constraint(time=lambda t: t > PartialDateTime(month=3,day=1)))
    nature = nature.extract(Constraint(time=lambda t: t > PartialDateTime(month=3,day=1)))

    return analys, nature, time

def extract_spread(field, dirname, time):
    analys = load_cube(f'{dirname}/anal_sprd.nc', field)

    # Get minimum duration of data
    analys = analys.extract(Constraint(time=lambda t: t < time))

    # Compute time mean after March 1st 00:00
    analys = analys.extract(Constraint(time=lambda t: t > PartialDateTime(month=3,day=1)))

    return analys

def plot_fields(dirname, color):
    with catch_warnings():
        # SPEEDY output is not CF compliant
        simplefilter('ignore', UserWarning)

        # Plot surface pressure
        print(f'Plotting Surface Pressure [Pa]')
        # Error
        analys, nature, time = extract_error(fields[0][0], dirname)
        error = ((analys - nature)**2).collapsed(['latitude', 'longitude', 'time'], MEAN)**0.5
        # Spread
        analys = extract_spread(fields[0][0], dirname, time)
        spread = analys.collapsed(['latitude', 'longitude', 'time'], MEAN)
        plt.scatter(error.data/fields[0][3], spread.data/fields[0][3], marker=fields[0][2], color=color, s=60*1.5**(len(levels)-1), alpha=0.5)

        # Plot other fields
        for field in fields[1:]:
            for num, lev in enumerate(levels):
                print(f'Plotting {field[0]} at sigma={lev}')
                # Error
                analys, nature = extract_error(field[0], dirname)[:2]
                analys = analys.extract(Constraint(atmosphere_sigma_coordinate=lev))
                nature = nature.extract(Constraint(atmosphere_sigma_coordinate=lev))
                error = ((analys - nature)**2).collapsed(['latitude', 'longitude', 'time'], MEAN)**0.5

                # Spread
                analys = extract_spread(field[0], dirname, time)
                analys = analys.extract(Constraint(atmosphere_sigma_coordinate=lev))
                spread = analys.collapsed(['latitude', 'longitude', 'time'], MEAN)

                plt.scatter(error.data/field[3], spread.data/field[3], marker=field[2], color=color, s=60*1.5**num, alpha=0.5)

# Change to relevant experiment directory
chdir(f'../experiments/{argv[1]}')

# Get colors
colors = plt.rcParams['axes.prop_cycle'].by_key()['color']

# Define levels and variables
levels = [0.095, 0.34, 0.51, 0.835, 0.95]
fields = [
        ('Surface Pressure [Pa]', 'Surface pressure', '*', 100.0),
        ('U-wind [m/s]', 'Zonal wind', '^', 1.0),
        ('V-wind [m/s]', 'Meriodional wind', 'v', 1.0),
        ('Temperature [K]', 'Temperature', 'o', 1.0),
        ('Specific Humidity [kg/kg]', 'Specific humidity', 'D', 0.001)
]

fig = plt.figure(figsize=(5,5), facecolor='white')

dirs = ['double', 'reduced']
labels= ['64 bits', '22 bits']

for d, c in zip(dirs, colors):
    print(f'Plotting {d}')

    plot_fields(d, c)

# Get axis limits and equalise
xlim = plt.gca().get_xlim()
ylim = plt.gca().get_ylim()
xlim = ylim = [min(xlim[0], ylim[0]), max(xlim[1], ylim[1])]
plt.xlim(xlim)
plt.ylim(ylim)

# Plot diagonal line
plt.plot(xlim, ylim, ls="--", c=".3")

plt.title('')
plt.xlabel('RMSE')
plt.ylabel('Spread')

# Legend for symbol
for field in fields:
    plt.scatter(-1, -1, s=90, marker=field[2], color='.3', label=field[1])

# Legend for color
plot_lines = [plt.plot([-1,-1.5], [-1,-1.5], color=colors[0])[0]]
plot_lines.append(plt.plot([-1,-1.5], [-1,-1.5], color=colors[1])[0])
col_leg = plt.legend(plot_lines, labels, loc=6, fontsize=12)

# Add both legends
plt.gca().add_artist(col_leg)
plt.legend(loc=2, fontsize=12)

plt.savefig(f'scatter_all_fields.pdf', bbox_inches='tight')
plt.show()
