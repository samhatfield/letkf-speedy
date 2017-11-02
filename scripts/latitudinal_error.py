"""
Plots RMSE of ensemble mean w.r.t. truth for SPEEDY/LETKF with 64 bit and 22 bit models, as function of
latitude. Pass the field and the vertical extent you want to plot as command line arguments.
"""

from warnings import catch_warnings, simplefilter

from os import chdir
from iris import load_cube, Constraint, FUTURE
from iris.analysis import MEAN
from iris.time import PartialDateTime
from matplotlib.dates import DateFormatter
from netcdftime import datetime
from sys import argv
from nc_time_axis import CalendarDateTime
from seaborn import plt
import seaborn as sns

sns.set_style('whitegrid', {'font.sans-serif': "Helvetica"})
sns.set_palette(sns.color_palette('Set1'))

def plot(dirname, field, vert_range, label):
    with catch_warnings():
        # SPEEDY output is not CF compliant
        simplefilter('ignore', UserWarning)

        # Load cubes
        print(f'Plotting {field}')
        analy = load_cube(f'{dirname}/mean.nc', field)
        nature = load_cube('nature.nc', field)
        sprd = load_cube(f'{dirname}/sprd.nc', field)
    
        # Get minimum duration of data
        time = min(analy.coord('time').points[-1], nature.coord('time').points[-1])
        analy = analy.extract(Constraint(time=lambda t: t < time))
        nature = nature.extract(Constraint(time=lambda t: t < time))
        sprd = sprd.extract(Constraint(time=lambda t: t < time))

        # Extract vertically over chosen vertical range
        lev_constraint_lambda = lambda s: s <= vert_range[0] and s > vert_range[1]

        # RMSE
        rmse = ((analy - nature)**2)\
                .extract(Constraint(atmosphere_sigma_coordinate=lev_constraint_lambda))\
                .collapsed(['atmosphere_sigma_coordinate', 'longitude'], MEAN)**0.5

        # Spread
        sprd = sprd.extract(Constraint(atmosphere_sigma_coordinate=lev_constraint_lambda))\
                .collapsed(['atmosphere_sigma_coordinate', 'longitude'], MEAN)
    
        # Compute time mean after March 1st 00:00
        with FUTURE.context(cell_datetime_objects=True):
            rmse = rmse.extract(Constraint(time=lambda t: t > PartialDateTime(month=3,day=1)))\
                    .collapsed('time', MEAN)
            sprd = sprd.extract(Constraint(time=lambda t: t > PartialDateTime(month=3,day=1)))\
                    .collapsed('time', MEAN)

        latitude_coord = rmse.coord('latitude')
        rmse_h, = plt.plot(latitude_coord.points, rmse.data, label=f'{label} error', linestyle='-')
        sprd_h, = plt.plot(latitude_coord.points, sprd.data, label=f'{label} spread', linestyle='--', color=rmse_h.get_color())

        return [rmse_h, sprd_h]

FUTURE.netcdf_promote = True

# Change to relevant experiment directory
chdir(f'../experiments/{argv[1]}')

fields = {
        'u': ('U-wind', '[m/s]'),
        'v': ('V-wind', '[m/s]'),
        't': ('Temperature', '[K]'),
        'q': ('Specific Humidity', '[kg/kg]')
}

vert_secs = [(1.0, 0.5), (0.5, 0.2), (0.2, 0.0)]

field = ' '.join(fields[argv[2]])

plt.figure(figsize=(5,5), facecolor='white')

dirs = ['double', 'reduced']
labels= ['64 bits', '22 bits']

handles = []

for d, l in zip(dirs, labels):
    print(f'Plotting {d}')

    handles += plot(d, field, vert_secs[int(argv[3])], l)

plt.xlabel('Latitude')
plt.ylabel(f'{fields[argv[2]][0]} {fields[argv[2]][1]}')
plt.title('')

# Add legend
leg = plt.legend(handles=handles, frameon=True, ncol=2, loc='lower center')
rect = leg.get_frame()
rect.set_linewidth(0.0)
rect.set_alpha(0.7)

plt.savefig(f'latitudinal_error_{argv[2]}_{argv[3]}.pdf', bbox_inches='tight')
plt.show()
