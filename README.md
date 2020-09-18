
<!-- README.md is generated from README.Rmd. Please edit that file -->

# vtuner

<!-- badges: start -->

<!-- badges: end -->

## Installation

vtuner relies on the rstan interface to [Stan](https://mc-stan.org). To
install vtuner, first [follow instructions for setting up
rstan](https://github.com/stan-dev/rstan/wiki/RStan-Getting-Started).

After successfully installing rstan, vtuner can be installed with
devtools

``` r
# install.packages(devtools)
library(devtools)
devtools::install_gitlab("psadil/vtuner")
```

# Example Analysis

## Data

A sample dataset is provided with this package. The dataset contains the
beta values for a single participant, and shows the format expected by
the functions of this package. The dataset can be loaded with the
following command.

``` r
# library(vtuner)
data("sub02")
knitr::kable(head(sub02))
```

| sub | run | voxel  | contrast | orientation |          y | ses |
| :-- | :-- | :----- | :------- | ----------: | ---------: | :-- |
| 2   | 15  | 191852 | low      |   0.7853982 |   3.359860 | 3   |
| 2   | 15  | 197706 | low      |   0.7853982 | \-2.839522 | 3   |
| 2   | 15  | 197769 | low      |   0.7853982 | \-2.027267 | 3   |
| 2   | 15  | 197842 | low      |   0.7853982 |   2.234859 | 3   |
| 2   | 15  | 197906 | low      |   0.7853982 |   2.858387 | 3   |
| 2   | 15  | 197907 | low      |   0.7853982 |   1.506754 | 3   |

For extra info on the dataset, see the help page for betas (?betas).

## Run Stan

The technique works by comparing separate models, each of which allows
just a single kind of modulation to the neural tuning functions. The two
kinds of neuromodulation currently implemented are *Additive* and
*Multiplicative*. Source for the models can be found on this [package’s
repository](https://gitlab.com/psadil/vtuner/tree/master/src/stan_files).
The three models are largely the same, differing only slightly in the
NTFs for the high contrast.

### Define Stan options

In this simple example, most voxel-wise parameters are not saved (e.g.,
the weights for each channel in each voxel, the value of the modulation
parameter for each voxel). Excluding these parameters drastically
reduces the size of the output and speeds up post-processing. The
parameter *mu*, which is the distribution of the beta values for each
trial, might also be worth dropping. *mu* is kept here because it is
required for model comparison.

A few additional parameters are used to control Stan’s sampling
behavior. See the help page for rstan::stan. Running one chain may
require a few hours.

``` r

#' number of chains to run
chains <- 8
#' number of cores to run the chains on
#' this value would run each chain on a separate core
cores <- 8 

#' seed for reproducible results!
seed <- 1234

#' number of posterior samples will be iter - warmup
warmup <- 1000
iter <- 1500

#' these parameters slow the sampling procedure down from the default
#' values in rstan, but are often required on these models
max_treedepth <- 12
adapt_delta <- 0.99

# parameters that will not be saved in the output
pars <- c("v_base","v_weights","v_base_raw","ntfp","ntfp_raw")
```

### Multiplicative

``` r
fitm <- run_stan(d=betas, 
                 model = "multiplicative", 
                 chains = chains, 
                 cores=cores, 
                 seed = seed,
                 warmup = warmup,
                 iter = iter,
                 pars = pars,
                 include = FALSE,
                 control = list(adapt_delta = adapt_delta,
                               max_treedepth = max_treedepth)
)
```

### Additive

``` r
fita <- run_stan(d=betas, 
                 model = "additive", 
                 chains = chains, 
                 cores = cores, 
                 seed = seed, 
                 iter = iter,
                 warmup = warmup,
                 pars = pars,
                 include = FALSE,
                 control = list(adapt_delta = adapt_delta,
                               max_treedepth = max_treedepth)
                 )
```

### Sharpening

Even with the relatively conservative sampling parameters (high
adapt\_delta, large max\_treedepth), the sharpening model will likely
fail some diagnostic checks on the provided data. This is due to the
sharpening model’s inability to capture the overal higher betas at
higher contrast.

``` r
fits <- run_stan(d=betas, 
                 model = "sharpening", 
                 chains = chains, 
                 cores = cores, 
                 seed = seed, 
                 iter = iter,
                 warmup = warmup,
                 pars = pars,
                 include = FALSE,
                 control = list(adapt_delta = adapt_delta,
                               max_treedepth = max_treedepth)
                 )
```

## Model Comparison

There are many ways of running model comparison. Here, I’m using
PSIS-LOO. The function, *loo*, in the following chunk is a method for
the generic defined in the *loo* package.

``` r
m <- loo(fitm)
a <- loo(fita)
```

The outputs of these functions are loo objects which can be passed
directly to the loo package functions.

``` r
loo::loo_compare(m, a)
```

Model comparison suggests that the multiplicative model fits best for
this participant.
