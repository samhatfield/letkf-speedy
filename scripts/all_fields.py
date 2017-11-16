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
    analys = load_cube(f'{dirname}/mean.nc', field)
    nature = load_cube('nature.nc', field)

    # Get minimum duration of data
    time = min(analys.coord('time').points[-1], nature.coord('time').points[-1])
    analys = analys.extract(Constraint(time=lambda t: t < time))
    nature = nature.extract(Constraint(time=lambda t: t < time))

    # Compute time mean after March 1st 00:00
    with FUTURE.context(cell_datetime_objects=True):
        analys = analys.extract(Constraint(time=lambda t: t > PartialDateTime(month=3,day=1)))
        nature = nature.extract(Constraint(time=lambda t: t > PartialDateTime(month=3,day=1)))

    return analys, nature, time

def extract_spread(field, dirname, time):
    analys = load_cube(f'{dirname}/sprd.nc', field)

    # Get minimum duration of data
    analys = analys.extract(Constraint(time=lambda t: t < time))

    # Compute time mean after March 1st 00:00
    with FUTURE.context(cell_datetime_objects=True):
        analys = analys.extract(Constraint(time=lambda t: t > PartialDateTime(month=3,day=1)))

    return analys

def plot_fields(dirname, label_in):
    with catch_warnings():
        # SPEEDY output is not CF compliant
        simplefilter('ignore', UserWarning)

        # Arrays that stores each field's error and spread
        errors = []
        spread = []
    
        # Plot surface pressure
        print(f'Plotting Surface Pressure [Pa]')
        analys, nature, time = extract_error(fields[0][0], dirname)
        errors.append(((analys - nature)**2).collapsed(['latitude', 'longitude', 'time'], MEAN)**0.5)
    
        # Plot other fields
        for field in fields[1:]:
            print(f'Plotting {field[0]}')
            analys, nature = extract_error(field[0], dirname)[:2]
            errors.append(((analys - nature)**2)\
                    .collapsed(['latitude', 'longitude', 'time', 'atmosphere_sigma_coordinate'], MEAN)**0.5)

        # Plot surface pressure
        print(f'Plotting Surface Pressure [Pa]')
        analys = extract_spread(fields[0][0], dirname, time)
        spread.append(analys.collapsed(['latitude', 'longitude', 'time'], MEAN))
    
        # Plot other fields
        for field in fields[1:]:
            print(f'Plotting {field[0]}')
            analys = extract_spread(field[0], dirname, time)
            spread.append(analys\
                    .collapsed(['latitude', 'longitude', 'time', 'atmosphere_sigma_coordinate'], MEAN))

        # Normalise the errors with respect to the observation error
        errors = [float(e.data.data)/o for e, o in zip(errors, obs_errors)]
        spread = [float(s.data.data)/o for s, o in zip(spread, obs_errors)]

        label = label_in + ' RMSE'
        rmse_h, = plt.plot(errors, label=label)
        label = label_in + ' spread'
        sprd_h, = plt.plot(spread, linestyle='--', label=label, color=rmse_h.get_color())
        plt.setp(plt.gca().get_xticklabels(), visible=True)
        plt.xticks(range(len(fields)), [f[1] for f in fields])
    
        return [rmse_h, sprd_h]

FUTURE.netcdf_promote = True

# Change to relevant experiment directory
chdir(f'../experiments/{argv[1]}')

obs_errors = [100, 1.0, 1.0, 1.0, 0.001]
levels = [0.95, 0.835, 0.685, 0.51, 0.34, 0.2, 0.095, 0.025]
fields = [
        ('Surface Pressure [Pa]', 'ps'),
        ('U-wind [m/s]', 'u'),
        ('V-wind [m/s]', 'v'),
        ('Temperature [K]', 'T'),
        ('Specific Humidity [kg/kg]', 'q')
]

plt.figure(figsize=(8,3), facecolor='white')

dirs = ['double', 'reduced']
labels= ['64 bits', '22 bits']

handles = []
for d, l in zip(dirs, labels):
    print(f'Plotting {d}')

    handles += plot_fields(d, l)

plt.title('')

# Add legend
leg = plt.legend(handles=handles, frameon=True, ncol=2)
rect = leg.get_frame()
rect.set_linewidth(0.0)
rect.set_alpha(0.7)

plt.savefig(f'all_fields.pdf', bbox_inches='tight')
plt.show()
