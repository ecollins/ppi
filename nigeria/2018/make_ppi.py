# 0. Setup

## Imports
### Set seed
## Config read-in

# 1. Load Stata Dataset


# 2. Split data into test and training datasets

## Construct penalty vector (or otherwise calibrate model if not penalize regression)


# 3. Choose candidate indicators


## Runs bootstrap_variable_select

  # Runs the model on a grid of lambdas and chooses the coefficients associated with the
  # lambda that minimizes the ten-fold cross-validation error. This is done "bootstrap_reps" (usually 1000)
  # times and creates a matrix with a distribution of all coefficients. The sample size of each
  # bootstrap is a fraction of the train set. We calculate a rate of appearance for each question
  # and select those questions that appeared to be used in more models.

# 4. Choose alpha that minimizes cv error once candidate indicators are chosen.

  #Runs the model on the trained data set only. It runs the data on a set of different alphas to see which minimizes error.
  #It runs it a set of times so that lambda is not dependent of the randomnsess of the ten-fold cross-validation error.
  #The alpha that minimizes the cross validation error is chosen 

# 5. Given the chosen alpha, we choose lambda that minimizes cv error

# 6. Transform coefficients and get scorecard

# 7. Predict fitted values based on the elastic-net model and create a function that maps the relationship 

      # of these fitted values vs the adjusted values that go from 0 to 100 that we created
      # Based on the sigmoid function (the one used in logit and the elastic net regression), estimate probabilities for the trainning set

# 8. Etimate prediction errors on the test set (targetting and poverty rates)

# 9. Select indicators, lambda and alpha again for the WHOLE SAMPLE

  # Basically just re-does steps 4 and 5 again
  # Need to review R code to figure out the point of doing this for the CV case then for the full sample.
    

pass