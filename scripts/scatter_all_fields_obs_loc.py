from warnings import catch_warnings, simplefilter
from os import chdir
from sys import argv
from iris import FUTURE, load_cube, Constraint
from iris.analysis import MEAN
from iris.time import PartialDateTime
from seaborn import plt
import seaborn as sns
from numpy import concatenate, linspace, loadtxt, int32

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

def extract_obs_locs(field, obs_locs):
    mean = 0.0
    for lon, lat in obs_locs:
        mean += field.extract(Constraint(longitude=lon) & Constraint(latitude=lat)).data
        
    mean /= len(obs_locs)
    return mean

def plot_fields(dirname, color, obs_locs):
    with catch_warnings():
        # SPEEDY output is not CF compliant
        simplefilter('ignore', UserWarning)

        # Plot surface pressure
        print(f'Plotting Surface Pressure [Pa]')
        # Error
        analys, nature, time = extract_error(fields[0][0], dirname)
        error = ((analys - nature)**2).collapsed(['time'], MEAN)**0.5
        error = extract_obs_locs(error, obs_locs)
        # Spread
        analys = extract_spread(fields[0][0], dirname, time)
        spread = analys.collapsed(['time'], MEAN)
        spread = extract_obs_locs(spread, obs_locs)
        plt.scatter(error/fields[0][3], spread/fields[0][3], marker=fields[0][2], color=color, s=20*1.5**(len(levels)-1), alpha=0.5)
    
        # Plot other fields
        for field in fields[1:]:
            for num, lev in enumerate(levels):
                print(f'Plotting {field[0]} at sigma={lev}')
                # Error
                analys, nature = extract_error(field[0], dirname)[:2]
                analys = analys.extract(Constraint(atmosphere_sigma_coordinate=lev))
                nature = nature.extract(Constraint(atmosphere_sigma_coordinate=lev))
                error = ((analys - nature)**2).collapsed(['time'], MEAN)**0.5
                error = extract_obs_locs(error, obs_locs)

                # Spread
                analys = extract_spread(field[0], dirname, time)
                analys = analys.extract(Constraint(atmosphere_sigma_coordinate=lev))
                spread = analys.collapsed(['time'], MEAN)
                spread = extract_obs_locs(spread, obs_locs)                
                plt.scatter(error/field[3], spread/field[3], marker=field[2], color=color, s=20*1.5**num, alpha=0.5)

FUTURE.netcdf_promote = True

# Change to relevant experiment directory
chdir(f'../experiments/{argv[1]}')

# Define T30 grid
lons = linspace(0.0, 360.0, 96, endpoint=False)

lats = [0] * 48
lats[0]  = -87.159
lats[1]  = -83.479
lats[2]  = -79.777
lats[3]  = -76.070
lats[4]  = -72.362
lats[5]  = -68.652
lats[6]  = -64.942
lats[7]  = -61.232
lats[8]  = -57.521
lats[9]  = -53.810
lats[10] = -50.099
lats[11] = -46.389
lats[12] = -42.678
lats[13] = -38.967
lats[14] = -35.256
lats[15] = -31.545
lats[16] = -27.833
lats[17] = -24.122
lats[18] = -20.411
lats[19] = -16.700
lats[20] = -12.989
lats[21] =  -9.278
lats[22] =  -5.567
lats[23] =  -1.856
lats[24] =   1.856
lats[25] =   5.567
lats[26] =   9.278
lats[27] =  12.989
lats[28] =  16.700
lats[29] =  20.411
lats[30] =  24.122
lats[31] =  27.833
lats[32] =  31.545
lats[33] =  35.256
lats[34] =  38.967
lats[35] =  42.678
lats[36] =  46.389
lats[37] =  50.099
lats[38] =  53.810
lats[39] =  57.521
lats[40] =  61.232
lats[41] =  64.942
lats[42] =  68.652
lats[43] =  72.362
lats[44] =  76.070
lats[45] =  79.777
lats[46] =  83.479
lats[47] =  87.159

station_lon, station_lat = loadtxt('../../obs/networks/real.txt', dtype=int32, skiprows=2, unpack=True)
obs_locs = [(lons[lon-1], lats[lat-1]) for lon, lat in zip(station_lon, station_lat)]

print(obs_locs)

# Get colors
colors = plt.rcParams['axes.prop_cycle'].by_key()['color']

# Define levels and variables
levels = [0.025, 0.095, 0.2, 0.34, 0.51, 0.685, 0.835, 0.95]
fields = [
        ('Surface Pressure [Pa]', 'Surface pressure', '*', 100.0),
        ('U-wind [m/s]', 'Zonal wind', '^', 1.0),
        ('V-wind [m/s]', 'Meriodional wind', '>', 1.0),
        ('Temperature [K]', 'Temperature', 'o', 1.0),
        ('Specific Humidity [kg/kg]', 'Specific humidity', 'D', 0.001)
]

fig = plt.figure(figsize=(5,5), facecolor='white')

dirs = ['double', 'reduced']
labels= ['64 bits', '22 bits']

for d, c in zip(dirs, colors):
    print(f'Plotting {d}')

    plot_fields(d, c, obs_locs)

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
