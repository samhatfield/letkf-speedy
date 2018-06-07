import matplotlib.pyplot as plt
from os import chdir
from iris import load_cube, Constraint
from iris.analysis import MEAN, STD_DEV
from iris.analysis.maths import abs
from iris.time import PartialDateTime
import cartopy.crs as ccrs
from cartopy.feature import LAND
from numpy import sqrt
from numpy.ma import masked
from sys import argv

def scatter_field(cube, significant, label='', symmetric_cbar=False):
    # Convert innovations into a form that can be scatter plotted
    lats = []; lons = []; innovs = []
    # Loop over latitude
    for lat_i in range(len(cube.data[:,1])):
        # Loop over longitude
        for lon_i in range(len(cube.data[1,:])):
            # Don't plot missing values
            if cube.data[lat_i,lon_i] is not masked and significant[lat_i,lon_i]:
                lats.append(cube.coord('latitude').points[lat_i])
                lons.append(cube.coord('longitude').points[lon_i])
                innovs.append(cube.data[lat_i,lon_i])

    color_map = plt.get_cmap('RdYlBu') if symmetric_cbar else plt.get_cmap('inferno')
    fig = plt.figure(figsize=(8,5))
    ax = plt.axes(projection=ccrs.PlateCarree())
    ax.add_feature(LAND, facecolor='0.5')
    ax.set_global()
    cont = plt.scatter(lons, lats, s=22, c=innovs, transform=ccrs.PlateCarree(), cmap=color_map, zorder=2)
    cb = plt.colorbar(cont, orientation='horizontal', fraction=0.0375, pad=0.02, aspect=50)
    cb.set_label(label)
    plt.tight_layout()

    if symmetric_cbar:
        mean_innov = 0.0
        width = max(max(innovs)-mean_innov, mean_innov-min(innovs))
        plt.clim(mean_innov - width, mean_innov + width)

# Get experiment name
experiment = argv[1]

# Set precision
prec = argv[2]

# Choose field to plot
field = argv[3]

# Set sigma level if present
if len(argv) > 4:
    sigma = float(argv[4])

# Change to relevant experiment directory
chdir(f'../experiments/{experiment}')

# Get background ensemble mean
background = load_cube(f'{prec}/gues_mean.nc', field)

# Get observations
observations = load_cube('obs.nc', field)

# Compute innovations
innovations = background - observations

# Extract level if not computing surface pressure innovations
if field != 'Surface Pressure [Pa]':
    innovations = innovations.extract(Constraint(atmosphere_sigma_coordinate=sigma))

# Compute time statistics after March 1st 00:00
innovations = innovations.extract(Constraint(time=lambda t: t > PartialDateTime(month=3,day=1)))

# Compute mean and standard deviation of innovations
innov_mean = innovations.collapsed('time', MEAN)
innov_std  = innovations.collapsed('time', STD_DEV)

# Compute mask for statistical significance (> 1.96σ from 0.0)
significant = abs(innov_mean/(innov_std/sqrt(innovations.coord('time').points.shape[0]))).data > 1.96

# Plot innovation mean and standard deviation on a map
scatter_field(innov_mean, significant, label=field, symmetric_cbar=True)
filename = f'innovs_{"".join([c for c in field if c.isalnum()]).rstrip()}_{prec}'
if len(argv) > 4:
    filename += f'_{sigma}'
plt.savefig(f'{filename}.pdf', bbox_inches='tight')
plt.show()
