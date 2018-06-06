import matplotlib.pyplot as plt
from os import chdir
from iris import load_cube, Constraint, FUTURE
from iris.analysis import MEAN, STD_DEV
from iris.time import PartialDateTime
import cartopy.crs as ccrs
import iris.plot as iplt
from numpy import isnan, mean
from numpy.ma import masked
from sys import argv

FUTURE.netcdf_promote = True

def scatter_field(cube, title='', symmetric_cbar=False):
    # Convert innovations into a form that can be scatter plotted
    lats = []; lons = []; innovs = []
    # Loop over latitude
    for lat_i in range(len(cube.data[:,1])):
        # Loop over longitude
        for lon_i in range(len(cube.data[1,:])):
            # Don't plot missing values
            if cube.data[lat_i,lon_i] is not masked:
                lats.append(cube.coord('latitude').points[lat_i])
                lons.append(cube.coord('longitude').points[lon_i])
                innovs.append(cube.data[lat_i,lon_i])

    color_map = plt.get_cmap('RdBu') if symmetric_cbar else plt.get_cmap('inferno')
    fig = plt.figure(figsize=(10,6))
    ax = plt.axes(projection=ccrs.PlateCarree())
    ax.coastlines()
    ax.set_global()
    cont = plt.scatter(lons, lats, s=26, c=innovs, transform=ccrs.PlateCarree(), cmap=color_map)
    plt.title(title)
    plt.colorbar(cont, orientation='horizontal', fraction=0.0375, pad=0.02, aspect=50)
    plt.tight_layout()

    if symmetric_cbar:
        mean_innov = 0.0
        width = max(max(innovs)-mean_innov, mean_innov-min(innovs))
        plt.clim(mean_innov - width, mean_innov + width)

# Get experiment name
experiment = argv[1]

# Set precision
prec = argv[2]

# Set sigma level
sigma = float(argv[3])

# Choose field to plot
field = argv[4]

# Change to relevant experiment directory
chdir(f'../experiments/{experiment}')

# Get background ensemble mean
background = load_cube(f'{prec}/gues_mean.nc', field)

# Get observations
observations = load_cube('obs.nc', field)

# Compute innovations
innovations = background - observations

# Extract time and level
innovations = innovations.extract(Constraint(atmosphere_sigma_coordinate=sigma))

# Compute time statistics after March 1st 00:00
with FUTURE.context(cell_datetime_objects=True):
    innovations = innovations.extract(Constraint(time=lambda t: t > PartialDateTime(month=3,day=1)))

# Plot innovation mean and standard deviation on a map
scatter_field(innovations.collapsed('time', MEAN), 'Innovation mean', True)
scatter_field(innovations.collapsed('time', STD_DEV), 'Innovation standard deviation')
plt.show()
