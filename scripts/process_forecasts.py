"""
Computes RMSE of medium range forecasts initialised from SPEEDY-LETKF system.
"""

from warnings import catch_warnings, simplefilter
from os import chdir
from iris import load_cube, FUTURE, Constraint, save
from iris.analysis import SUM
from iris.util import unify_time_units
from datetime import datetime, timedelta
from sys import argv

def load_all_fields(filename):
    return [load_cube(filename, field) for field in fields]

FUTURE.netcdf_promote = True
FUTURE.netcdf_no_unlimited = True

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
levels_sig = [0.95, 0.835, 0.685, 0.51, 0.34, 0.2, 0.095, 0.025]

# Length of forecasts in days
length = 15

# Location of forecasts
forecast_dir = f'forecasts'

# Load nature run
nature_full = load_all_fields('nature.nc')

# Define start and end dates of forecasts
start = datetime(1982,3,1,0)
end   = datetime(1983,2,14,0)

# For storing RMSE
rmse = None

# All 6 hour dates between start and end
date_range = [start + timedelta(hours=i*6) for i in range(int((end-start).total_seconds()/21600))]

# Loop over all 6 hour intervals from start to end
for n_fcsts, date in enumerate(date_range, 1):
    print(date)
    
    # Load this forecast
    forecast = load_all_fields(f'{forecast_dir}/{date:%Y%m%d%H}.nc')

    # Unify time coordinates
    for f, n in zip(forecast, nature_full):
        unify_time_units([f,n])

    # Extract corresponding part of nature run
    nature = [n.subset(forecast[0].coord('time')) for n in nature_full]

    # Compute globally averaged RMSE
    # Start with surface pressure
    with catch_warnings():
        simplefilter('ignore', UserWarning)
        ps_rmse = (((forecast[0] - nature[0])/obs_errors[0])**2).collapsed(['latitude', 'longitude'], SUM)
        if rmse is None:
            rmse = ps_rmse
            rmse.rename('RMSE')
        else:
            rmse += ps_rmse.data

    # Then compute 3D fields
    for natu, fcst, obs_error in zip(nature[1:], forecast[1:], obs_errors[1:]):
#        # Harmonize coordinates
#        fcst.coord('generic').points = natu.coord('generic').points

        with catch_warnings():
            simplefilter('ignore', UserWarning)
            rmse += (((natu - fcst)/obs_error)**2).collapsed(['latitude', 'longitude', 'atmosphere_sigma_coordinate'], SUM).data

    save((rmse/(n_fcsts*33.0*96.0*48.0))**0.5, 'forecast_rmse.nc')
