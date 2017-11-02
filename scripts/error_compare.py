"""
Plots total (across all fields and levels) RMSE of ensemble mean w.r.t. truth for SPEEDY/LETKF with 64 bit and 22 bit models.
For each field, the error is normalised by the observation error before averaging together.
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

def plot(dirname, field, label_in):
    with catch_warnings():
        label = label_in

        # SPEEDY output is not CF compliant
        simplefilter('ignore', UserWarning)

        print(f'Plotting {field}')
        analy_ps = load_cube(f'{dirname}/mean.nc', field)
        nature_ps = load_cube('nature.nc', field)
    
        # Get minimum duration of data
        time = min(analy_ps.coord('time').points[-1], nature_ps.coord('time').points[-1])
        analy_ps = analy_ps.extract(Constraint(time=lambda t: t < time))
        nature_ps = nature_ps.extract(Constraint(time=lambda t: t < time))

        # Generate x date axis
        with FUTURE.context(cell_datetime_objects=True):
            time_axis = [x.point for x in nature_ps.coord('time').cells()]

        coords = ['latitude', 'longitude', 'atmosphere_sigma_coordinate']
        rmse = ((analy_ps - nature_ps)**2).collapsed(coords, MEAN)**0.5
    
        label = label_in + ' RMSE'

        # Try to compute time mean after March 1st 00:00 (if data doesn't go up to March 1st yet,
        # an AttributeError will be thrown - this is ignored
        try:
            with FUTURE.context(cell_datetime_objects=True):
                after_march = rmse.extract(Constraint(time=lambda t: t > PartialDateTime(month=3,day=1)))
                mean = float(after_march.collapsed('time', MEAN).data)
            label += f' ({mean:{4}.{3}})'
        except AttributeError:
            pass
    
        rmse_h, = plt.plot(time_axis, rmse.data, label=label)

        analy_cb = load_cube(f'{dirname}/sprd.nc', field)
        analy_cb = analy_cb.extract(Constraint(time=lambda t: t < time))

        sprd = analy_cb.collapsed(coords, MEAN)

        label = label_in + ' spread'

        # Try to compute time mean after March 1st 00:00 (if data doesn't go up to March 1st yet,
        # an AttributeError will be thrown - this is ignored
        try:
            with FUTURE.context(cell_datetime_objects=True):
                after_march = sprd.extract(Constraint(time=lambda t: t > PartialDateTime(month=3,day=1)))
                mean = float(after_march.collapsed('time', MEAN).data)
            label += f'  ({mean:{4}.{3}})'
        except AttributeError:
            pass

        sprd_h, = plt.plot(time_axis, sprd.data, linestyle='--', label=label, color=rmse_h.get_color())

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

plt.rc('lines', linewidth=1.0)
plt.style.use('ggplot')

plt.figure(figsize=(9,3), facecolor='white')

dirs = ['double']
labels= ['64 bits']

handles = []

for d, l in zip(dirs, labels):
    print(f'Plotting {d}')

    handles += plot(d, fields[argv[2]][0], l)

plt.ylim([0, 3.5])
plt.xlabel('Time')
plt.ylabel(f'{fields[argv[2]][1]}')
plt.title('')

# Add legend
leg = plt.legend(handles=handles, frameon=True, ncol=2)
rect = leg.get_frame()
rect.set_linewidth(0.0)
rect.set_alpha(0.7)

plt.savefig(f'error_compare_{argv[2]}.pdf', bbox_inches='tight')
plt.show()
