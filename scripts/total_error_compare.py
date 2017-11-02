"""
Plots total (across all fields and levels) RMSE of ensemble mean w.r.t. truth for SPEEDY/LETKF with 64 bit and 22 bit models.
For each field, the error is normalised by the observation error before averaging together.
"""

from warnings import catch_warnings, simplefilter

from os import chdir
from iris import load_cube, Constraint, FUTURE
from iris.analysis import SUM, MEAN
from iris.time import PartialDateTime
from matplotlib.dates import DateFormatter
from netcdftime import datetime
from sys import argv
from nc_time_axis import CalendarDateTime
from seaborn import plt
import seaborn as sns

sns.set_style('whitegrid', {'font.sans-serif': "Helvetica"})
sns.set_palette(sns.color_palette('Set1'))

def plot(dirname, label_in):
    with catch_warnings():
        label = label_in

        # SPEEDY output is not CF compliant
        simplefilter('ignore', UserWarning)

        print(f'Plotting {fields[0]}')
        analy_ps = load_cube(f'{dirname}/mean.nc', fields[0])
        nature_ps = load_cube('nature.nc', fields[0])
    
        # Get minimum duration of data
        time = min(analy_ps.coord('time').points[-1], nature_ps.coord('time').points[-1])
        analy_ps = analy_ps.extract(Constraint(time=lambda t: t < time))
        nature_ps = nature_ps.extract(Constraint(time=lambda t: t < time))

        # Generate x date axis
        with FUTURE.context(cell_datetime_objects=True):
            time_axis = [x.point for x in nature_ps.coord('time').cells()]

        rmse = (((analy_ps - nature_ps)/obs_errors[0])**2).collapsed(['latitude', 'longitude'], SUM)
    
        for field, obs_error in zip(fields[1:], obs_errors[1:]):
            print(f'Plotting {field}')
            for lev in levels:
                # Build iris constraint object
                lev_con = Constraint(atmosphere_sigma_coordinate=lev)

                analy_ps = load_cube(f'{dirname}/mean.nc', field)
                nature_ps = load_cube(f'nature.nc', field)

                analy_ps = analy_ps.extract(Constraint(time=lambda t: t < time) & lev_con)
                nature_ps = nature_ps.extract(Constraint(time=lambda t: t < time) & lev_con)

                rmse += (((analy_ps - nature_ps)/obs_error)**2).collapsed(['latitude', 'longitude'], SUM)
    
        # Divide by the total number of fields (4 3D fields x 8 levels + 1 2D field) and gridpoints (96*48)
        rmse = rmse / (33.0*96.0*48.0)
        
        # Square root to get RMSE
        rmse = rmse ** 0.5
    
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

        for field, obs_error in zip(fields, obs_errors):
            print(f'Plotting {field}')
            analy_cb = load_cube(f'{dirname}/sprd.nc', field)
            analy_cb = analy_cb.extract(Constraint(time=lambda t: t < time))
            if field == 'Surface Pressure [Pa]':
                try:
                    sprd += (analy_cb/obs_error).collapsed(['latitude', 'longitude'], SUM)
                except NameError:
                    sprd = (analy_cb/obs_error).collapsed(['latitude', 'longitude'], SUM)
            else:
                for lev in levels:
                    analy_cb_lev = analy_cb.extract(Constraint(atmosphere_sigma_coordinate=lev))
                    try:
                        sprd += (analy_cb_lev/obs_error).collapsed(['latitude', 'longitude'], SUM)
                    except NameError:
                        sprd = (analy_cb_lev/obs_error).collapsed(['latitude', 'longitude'], SUM)

        # Divide by the total number of fields (4 3D fields x 8 levels + 1 2D field) and gridpoints (96*48)
        sprd = sprd / (33.0*96.0*48.0)

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

fields = [
        'Surface Pressure [Pa]',
        'U-wind [m/s]',
        'V-wind [m/s]',
        'Temperature [K]',
        'Specific Humidity [kg/kg]'
]

obs_errors = [100, 1.0, 1.0, 1.0, 0.001]
levels = [0.95, 0.835, 0.685, 0.51, 0.34, 0.2, 0.095, 0.025]

plt.rc('lines', linewidth=1.0)

plt.figure(figsize=(9,3), facecolor='white')

dirs = ['double']
labels= ['64 bits']

handles = []

for d, l in zip(dirs, labels):
    print(f'Plotting {d}')

    handles += plot(d, l)

plt.ylim([0, 3.5])
plt.xlabel('Time')
plt.ylabel(f'Total analysis RMSE')
plt.title('')

# Add legend
leg = plt.legend(handles=handles, frameon=True, ncol=2)
rect = leg.get_frame()
rect.set_linewidth(0.0)
rect.set_alpha(0.7)

plt.savefig(f'total_error_compare.pdf', bbox_inches='tight')
plt.show()
