import numpy as np
from iris import load_cube, save, FUTURE
from iris.coords import DimCoord
from iris.cube import Cube, CubeList
from glob import glob
from os import chdir
from sys import argv

FUTURE.netcdf_no_unlimited = True

####################################################################################################

def create_cube(name, short_name, surface = False):
    time = DimCoord([6.0*v for v in range(ntime)], standard_name='time', var_name='time',\
        units='hours since 1982-01-01 00:00:00')
    latitude = DimCoord(lats, standard_name='latitude', var_name='lat', units='degrees')
    longitude = DimCoord(lons, standard_name='longitude', var_name='lon', units='degrees')
    level = DimCoord(sigmas, standard_name='atmosphere_sigma_coordinate', var_name='lev')

    coord_tuple = (ntime,nlat,nlon) if surface else (ntime,nlat,nlon,nlev)
    dummy = np.empty(coord_tuple)
    dummy[:] = np.nan
    if surface:
        return Cube(dummy, dim_coords_and_dims=[(time,0), (latitude, 1),(longitude, 2)],\
            long_name=name, var_name=short_name)
    else:
        return Cube(dummy, dim_coords_and_dims=[(time,0), (latitude, 1),(longitude, 2),(level,3)],\
            long_name=name, var_name=short_name)

####################################################################################################

# Change to relevant experiment directory
chdir(f'../experiments/{argv[1]}')

# Load nature run surface pressure for converting to sigma coordinates
nature_ps = load_cube('nature.nc', 'Surface Pressure [Pa]')

# Define fields
fields = [
    {'id': 14593, 'name': 'Surface Pressure [Pa]', 'short': 'ps'},
    {'id': 2819, 'name': 'U-wind [m/s]', 'short': 'u'},
    {'id': 2820, 'name': 'V-wind [m/s]', 'short': 'v'},
    {'id': 3073, 'name': 'Temperature [K]', 'short': 't'},
    {'id': 3330, 'name': 'Specific Humidity [kg/kg]', 'short': 'q'}
]

# Get Gaussian latitudes from GrADS control file
with open('../../common/t30.ctl') as f:
    content = f.readlines()[5]
    lats = [np.float32(lat) for lat in content.split()[3:]]

# Define longitudes
lons = np.arange(0, 360, 3.75)

# Define sigma coordinates
sigmas = [0.95, 0.835, 0.685, 0.51, 0.34, 0.2, 0.095, 0.025]

# Glob observation files
files = sorted(glob('obs/*.dat'))

# Define model state dimensions
ntime, nlat, nlon, nlev = len(files), 48, 96, 8

# Create cubes, filling with NaNs to begin with
cubes = [create_cube(fields[0]['name'], fields[0]['short'], surface=True)]
cubes += [create_cube(field['name'], field['short']) for field in fields[1:]]

# Loop over all observation files (each one represents one set of 6 hourly observations)
for t, file in enumerate(files):
    print(f'Processing {t+1} of {ntime} timesteps')
    # Read data from file
    data = np.reshape(np.fromfile(file, dtype=np.float32).byteswap(), (12064,8))

    # Delete first and last columns - these are used by FORTRAN to give the number of bytes
    # in between, i.e. the length of a row
    data = np.delete(data, [0,7], axis=1)

    # First process surface pressure
    ps_obs = data[data[:,0] == fields[0]['id']]
    for ob in ps_obs:
        lat_i = np.where(lats == ob[2])[0][0]
        lon_i = np.where(lons == ob[1])[0][0]
        cubes[0].data[t, lat_i, lon_i] = ob[4]

    # Now process the other fields
    for i, field in enumerate(fields[1:],1):
        # Get all observations of this field
        obs = data[data[:,0] == field['id']]
        for ob in obs:
            lat_i = np.where(lats == ob[2])[0][0]
            lon_i = np.where(lons == ob[1])[0][0]
            sigma = np.around(100.0*ob[3]/nature_ps.data[t, lat_i, lon_i], decimals=3)
            lev_i = np.where(sigmas == sigma)[0][0]
            cubes[i].data[t, lat_i, lon_i, lev_i] = ob[4]

save(CubeList(cubes), 'obs.nc', unlimited_dimensions=['time'])
print('Finished')
