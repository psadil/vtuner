data {
  int<lower=1> n;  // total number of observations
  int n_id;
  int<lower=1, upper=n_id> id[n];
  int n_tuning;
  int<lower=1, upper=n_tuning> tuning[n];
  int<lower=1, upper=n_tuning*n_id> id_tuning[n]; // index to pick out from matrix of tuning x id
  vector[n] y;  // response variable (high)
  vector[n] x;  // noisy values (low)

  // priors
  vector[2] prior_z_mu_mu;
  vector[2] prior_z_mu_sigma;
  vector[2] prior_z_sigma_mu;
  vector[2] prior_z_sigma_sigma;
  vector[2] prior_x_sigma_mu;
  vector[2] prior_x_sigma_sigma;
  vector[2] prior_y_sigma_mu;
  vector[2] prior_y_sigma_sigma;
  vector[2] prior_g_mu;
  vector[2] prior_g_sigma;
  vector[2] prior_a_mu;
  vector[2] prior_a_sigma;
}
parameters {
  real<lower=0> g_sigma;
  real g_mu;
  vector<multiplier=g_sigma, offset=g_mu>[n_id] g;
  real<lower=0> a_sigma;
  real a_mu;
  vector<multiplier=a_sigma, offset=a_mu>[n_id] a;
  real<lower=0> z_mu_sigma;
  real z_mu_mu;
  row_vector[n_id] z_mu;
  matrix[n_tuning, n_id] z_raw;
  real<lower=0> z_sigma_sigma;
  real<lower=0> z_sigma_mu;
  vector<lower=-z_sigma_mu/z_sigma_sigma>[n_id] z_sigma_raw;
  real<lower=0> x_sigma_sigma;
  real<lower=0> x_sigma_mu;
  vector<lower=0>[n_id] x_sigma;
  real<lower=0> y_sigma_sigma;
  real<lower=0> y_sigma_mu;
  vector<lower=0>[n_id] y_sigma;
}
transformed parameters{
  vector[n_tuning*n_id] zeta;

  {
    matrix[n_tuning, n_id] z;
    vector[n_id] z_sigma = fma(z_sigma_sigma, z_sigma_raw, z_sigma_mu);
    for (v in 1:n_id) z[,v] = z_sigma[v] * z_raw[,v] + z_mu[v];
    zeta = to_vector(z);
  }

}
model {
  z_mu_mu ~ normal(prior_z_mu_mu[1], prior_z_mu_mu[2]);
  z_mu_sigma ~ normal(prior_z_mu_sigma[1], prior_z_mu_sigma[2]);
  z_mu ~ normal(z_mu_mu, z_mu_sigma);

  to_vector(z_raw) ~ std_normal();

  z_sigma_mu ~ normal(prior_z_sigma_mu[1], prior_z_sigma_mu[2]);
  z_sigma_sigma ~ normal(prior_z_sigma_sigma[1], prior_z_sigma_sigma[2]);
  z_sigma_raw ~ std_normal();
  target += -normal_lccdf(-z_sigma_mu/z_sigma_sigma | 0, 1)*n_id;

  x_sigma_mu ~ normal(prior_x_sigma_mu[1], prior_x_sigma_mu[2]);
  x_sigma_sigma ~ normal(prior_x_sigma_sigma[1], prior_x_sigma_sigma[2]);
  x_sigma ~ normal(x_sigma_mu, x_sigma_sigma);
  target += -normal_lccdf(0 | x_sigma_mu, x_sigma_sigma) * n_id;

  y_sigma_mu ~ normal(prior_y_sigma_mu[1], prior_y_sigma_mu[2]);
  y_sigma_sigma ~ normal(prior_y_sigma_sigma[1], prior_y_sigma_sigma[2]);
  y_sigma ~ normal(y_sigma_mu, y_sigma_sigma);
  target += -normal_lccdf(0 | y_sigma_mu, y_sigma_sigma) * n_id;

  g_mu ~ normal(prior_g_mu[1], prior_g_mu[2]);
  g_sigma ~ normal(prior_g_sigma[1], prior_g_sigma[2]);
  g ~ normal(g_mu, g_sigma);

  a_mu ~ normal(prior_a_mu[1], prior_a_mu[2]);
  a_sigma ~ normal(prior_a_sigma[1], prior_a_sigma[2]);
  a ~ normal(a_mu, a_sigma);

  // likelihood
  x ~ normal(zeta[id_tuning], x_sigma[id]);
  y ~ normal(a[id] + zeta[id_tuning] .* g[id], y_sigma[id]);
}
