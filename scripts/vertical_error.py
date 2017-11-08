"""
Plots RMSE of ensemble mean w.r.t. truth for SPEEDY/LETKF with 64 bit and 22 bit models, as function of level.
Pass the field you want to plot as a command line argument.
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

def plot(dirname, field, label):
    with catch_warnings():
        # SPEEDY output is not CF compliant
        simplefilter('ignore', UserWarning)

        print(f'Plotting {field}')
        analy = load_cube(f'{dirname}/mean.nc', field)
        nature = load_cube('nature.nc', field)
    
        # Get minimum duration of data
        time = min(analy.coord('time').points[-1], nature.coord('time').points[-1])
        analy = analy.extract(Constraint(time=lambda t: t < time))
        nature = nature.extract(Constraint(time=lambda t: t < time))

        # RMSE
        rmse = ((analy - nature)**2).collapsed(['latitude', 'longitude'], MEAN)**0.5

        # Spread
        sprd = load_cube(f'{dirname}/sprd.nc', field).extract(Constraint(time=lambda t: t < time))
        sprd = sprd.collapsed(['latitude', 'longitude'], MEAN)
    
        # Compute time mean after March 1st 00:00
        with FUTURE.context(cell_datetime_objects=True):
            rmse = rmse.extract(Constraint(time=lambda t: t > PartialDateTime(month=3,day=1)))\
                    .collapsed('time', MEAN)
            sprd = sprd.extract(Constraint(time=lambda t: t > PartialDateTime(month=3,day=1)))\
                    .collapsed('time', MEAN)

        sigma_coord = rmse.coord('atmosphere_sigma_coordinate')
        rmse_h, = plt.plot(rmse.data, sigma_coord.points, label=f'{label} error', linestyle='-')
        sprd_h, = plt.plot(sprd.data, sigma_coord.points, label=f'{label} spread', linestyle='--', color=rmse_h.get_color())

        return [rmse_h, sprd_h]

FUTURE.netcdf_promote = True

# Change to relevant experiment directory
chdir(f'../experiments/{argv[1]}')

fields = {
        'u': ('U-wind [m/s]', 'Zonal wind (ms$^{-1}$)'),
        'v': ('V-wind [m/s]', 'Meridional wind (ms$^{-1}$)'),
        't': ('Temperature [K]', 'Temperature (K)'),
        'q': ('Specific Humidity [kg/kg]', 'Specific humidity (kg/kg)')
}

plt.figure(figsize=(5,5), facecolor='white')

dirs = ['double', 'reduced']
labels= ['64 bits', '22 bits']

handles = []

for d, l in zip(dirs, labels):
    print(f'Plotting {d}')

    handles += plot(d, fields[argv[2]][0], l)

plt.xlabel(f'{fields[argv[2]][1]}')
plt.ylabel('Sigma coordinate')
plt.ylim([1.0, 0.0])
plt.xlim([0.0, max(1.0, plt.gca().get_xlim()[1])])
plt.gca().set_xlim(left=0)
plt.title('')

# Add legend
leg = plt.legend(handles=handles, frameon=True, ncol=2, loc='lower center')
rect = leg.get_frame()
rect.set_linewidth(0.0)
rect.set_alpha(0.7)

plt.savefig(f'vertical_error_{argv[2]}.pdf', bbox_inches='tight')
plt.show()
