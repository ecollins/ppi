  ######################################################################################
  ################This section should be taylored to every particular survey############
  ######################################################################################
  # Clear workspace
  rm(list = ls())
  
  #Change to your working Directory
  root = "../../ppi-code"
  root2 = "./"
  # root = "C:/Users/Manuel Cardona Arias/Box Sync/IPA_Programs_PPI/07 PPI Development/ppi-code"
  # root2 = "C:/Users/Manuel Cardona Arias/Box Sync/IPA_Programs_PPI/07 PPI Development/Nigeria/2018"
  pre_p = paste(root,"/01 Pre-Process/", sep="") ##Pre-process functions are stored here
  fun_l = paste(root,"/02 Function Library/", sep="") ##All other functions used in this code are stored here
  clean = paste(root2,"/data/clean/", sep="") ##Data that was clean by STATA is kept here
  results = paste(root2, "/results/", sep="")
  
  #File names
  survey_data <-"PPI_Nigeria_2018.dta" #Database name
  question_key <-"Nigeria18_QuestionKEY.csv" #Key file name
  qkey_num <- 1 #Column number of question number (not variable name)
  
  # Choose variable that WILL BE predicted (dependent variables)
  target_base <- "poor_npl1" # target_base is the measure of poverty that used to select the questions: usually the National Poverty Line
  
  # target is the poverty classification that we are trying to predict.
  target <- c("poor_npl1")
  
  weight_name <- "wt_final" #Column name for household weight
  ID <- "hhid"
  
  # All the candidate features should be in adjacent columns (CHANGE THE FIRST AND LAST COLUMN)
  candidate_feature_first_col <- 22 #the column number of the first candidate indicator
  candidate_feature_last_col <- 146 #the column number of the last candidate indicator
  region_number <- 5 #Number of regions in question_key
  sub_question_number <- 1 #identify unique question number (from the key file) for the subnational questions
  numb_questions <- c(10) # Number of questions that are to be selected by the LASSO
  prop_trained <- 0.66 # Proportion of the sample used for the training data set (the final scorecard is based on the entire survey)
  
  #Bootstrapping options (shouldn't change them)
  alpha_i <-  0.5 # Ridge regression does not do variable selection (so alpha set to > 0)
  cv_nfold <- 10 #Number of folds used in the cross validation elastic nets
  bootstrap_size_selection <- 100 #Number of times we bootstrap to select indicators
  bootstrap_sample <- 500 #Number of obs the bootstrap draws randomly per iteration
  bootstrap_error_reps <- 100 #Number of times we bootstrap to calculate error rates
  bootstrap_sample_size <- c(100,200) #Sample sizes for bootstrapping errors - Targetting error.
  bootstrap_error_sample_size <- seq(from = 100, to = 200, by = 50) #Sample sizes for bootstrapping errors - Poverty rates
  
  ##############################################################################
  ##The rest of the script does not need to be tailored to a particular survey #
  ##############################################################################
  # Load libraries written by others
  library(foreign)
  library(glmnet)
  library(matrixStats)
  
  # Load PPI functions
  #The first two are in the "R_Code/Pre_Process/" folder, while the rest are in the ""R_Code/Function_Library/" folder
  source(paste(pre_p,"Input_Survey_Data.R", sep="")) # Inputs the survey data which is stored as a Stata data file
  source(paste(pre_p,"input_question_key.R", sep="")) # Inputs the csv question key (mapping questions to variables)
  source(paste(fun_l,"split_data.R", sep="")) # Splits the data into training and test sets for the purpose of confidence intervals etc. 
  source(paste(fun_l,"coefficients_elastic_net.R", sep="")) # Extracts the coefficients for the stability selection 
  source(paste(fun_l,"bootstrap_variable_select.R", sep="")) # Does the bootstrapping for the stability selection
  source(paste(fun_l,"stable_elastic_net.R", sep="")) # Estimates the elastic net for the selected questions  
  source(paste(fun_l,"prediction_function.R", sep="")) # Converts the final elastic net results to a predicted probability
  source(paste(fun_l,"bootstrap_poverty_test.R", sep="")) # Error Analysis based on percentage point errors  
  source(paste(fun_l,"bootstrap_test.R", sep="")) # Inclusion and Exclusion Errors 
  source(paste(fun_l,"scorecard_function.R", sep="")) # Converts the final elastic net results to a scorecard
  source(paste(fun_l,"unpenalized_logit.R", sep="")) # Unpenalized logistic regression function
  source(paste(fun_l,"create_lookup_table.R", sep="")) # creates a lookuptable from a general logit score and prob table
  source(paste(fun_l,"prob_lookup_table.R", sep="")) # converts scores to probabilities using the lookup table
  
  options(stringsAsFactors = FALSE)
  options(warn=-1)
  
  ################## STEP 1 : Load Stata data set ##################
  # Input the Stata data set (The function uses the read.dta function in the foreign package)
  survey_data <- Input_Stata_Data(data = survey_data)
  # We need to select 10 questions, not 10 variables; the question_key file numbers each variable with its question number
  # e.g. all regions would have the same question number so that they are considered as one variable
  # i.e. if one question is selected, all the dummy variables from the same question are also selected
  question_key <- input_question_key(data = question_key)
  
  ################## STEP 2: Load the mapping from the variable names to the question numbers
  # A: SPLIT THE DATA INTO TEST AND TRAINING SETS
  set.seed(1234)
  split_data <- split_data(data = survey_data, prop_trained = prop_trained)
  train_data <- split_data$train_data
  boot_sample_frac <- bootstrap_sample/nrow(train_data) #Calculate the sample fraction needed to have 'bootstrap_sample' observations per iteration
  test_data <- split_data$test_data
  # B: Construct a penalty factor vector that is 0 for the subnational question and 1 for other variables
  penalty_vector_full <- rep(1, times = nrow(question_key)) 
  penalty_vector_full[1:region_number]<-0
  
  
  ################# STEP 3: Choose candidate indicators 
  for (nq in numb_questions) { 
    #Loop over the number of questions that we want
    start_time <- Sys.time()
    print(paste("Looping through the ", nq, " question model."))
    alpha_cv_error <- c(NULL)
    lambda_cv_error <- c(NULL)
    stable_fit_list <- list(NULL)
    for (a in alpha_i) {
      # Runs the model on a grid of lambdas and chooses the coefficients associated with the
      # lambda that minimizes the ten-fold cross-validation error. This is done "bootstrap_reps" (usually 1000)
      # times and creates a matrix with a distribution of all coefficients. The sample size of each
      # bootstrap is a fraction of the train set. We calculate a rate of appearance for each question
      # and select those questions that appeared to be used in more models.
      selected_questions_training <- bootstrap_variable_select(data_boot = train_data,
                                                               bootstrap_sample_fraction = boot_sample_frac, bootstrap_reps = bootstrap_size_selection,
                                                               question_key = question_key, y= target_base, numb_questions=nq,
                                                               alpha = a, weight= weight_name, penalty_vector= penalty_vector_full)
      
      ################# STEP 4: Choose alpha that minimizes cv error
      #Runs the model on the trained data set only. It runs the data on a set of different alphas to see which minimizes error.
      #It runs it a set of times so that lambda is not dependent of the randomnsess of the ten-fold cross-validation error.
      #The alpha that minimizes the cross validation error is chosen 
      stable_fit_model <- stable_elastic_net(data = train_data, stable_coef = selected_questions_training,
                                             y = target_base, input_first_col = candidate_feature_first_col,
                                             input_last_col = candidate_feature_last_col, alpha = a, weight= weight_name)
      
      stable_fit <- stable_fit_model$final_elastic_net #This keeps the last elastic net we ran (no n-fold cross validation) from a specific alpha
      cv_error <-  stable_fit_model$min_cv_error #Minimum error found for a specific alpha
      alpha_cv_error <- c(alpha_cv_error,cv_error) #Put all the errors for each alpha together
      
      stable_fit_list[[length(stable_fit_list)+1]] <- stable_fit #We store the last elastic net we ran in a list along with all the other alphas
    }
    
    # Select Elastic Net with the Optimal Alpha
    selected_stable_elastic_net <- stable_fit_list[[which.min(alpha_cv_error) +1]] #This Elastic Net is the one with the alpha that has the lowest error
    coefficient_names_train <- c(as.vector(rownames(selected_stable_elastic_net$beta))) #Select the variables (typically 10) that will be used in the model
    optimal_alpha <- alpha_i[[which.min(alpha_cv_error)]] #Select the alpha that yielded the lowest cv error
    print("            Chose most predictive indicators")
    
    ################# STEP 5: Given the chosen alpha, we choose lambda that minimizes cv error
    #Runs the model on the trained data set only.
    targetting_error <- as.data.frame(matrix(NA, ncol = 14, nrow = 1))
    poverty_error <- as.data.frame(matrix(NA, ncol = 6, nrow = 1))
    
    print("                Looping through all pov rates to calibrate the model and estimate errors")
    for (pov in target) {
      # Run for every pov line now with chosen alpha
      stable_fit_train_list <- stable_elastic_net(data = train_data, stable_coef = coefficient_names_train ,
                                                  y = pov, input_first_col = candidate_feature_first_col, input_last_col = candidate_feature_last_col,
                                                  alpha = optimal_alpha, weight= weight_name)
      
      stable_fit_train <- stable_fit_train_list$final_elastic_net #This keeps the last elastic net we ran (no n-fold cross validation) 
      selected_lambda <-  stable_fit_train_list$median_lambda #We choose the median lambda that minimizes cross validation error (we already chose alpha) 
      coefficient_train_matrix <- as.matrix(coef.glmnet(stable_fit_train, s= selected_lambda)) #We keep the coefficient for the selected lambda
      coefficient_train <- coefficient_train_matrix[-1] #Store the coefficients of the model with the chosen lambda and alpha 
      
      ################# STEP 6: Transform coefficients and get scorecard
      #Transforms coefficients to produce scorecard
      # Scorecards and score for the training set: substract minimum absolute score, rescales, rounds.
      scorecardtrain <- scorecard_function (data = train_data, y= pov, coef_vector = coefficient_train,
                                            stable_coef_names = coefficient_names_train, question_key = question_key)
      
      scorecard_train <- scorecardtrain[[1]] #Store rescaled and rounded coefficients
      score_train <- scorecardtrain[[2]] #Store scores for all respondents in the trainning set
      # Scorecards and score for the test set: substract minimum absolute score, rescales, rounds.
      scorecardtest <- scorecard_function(data = test_data, y= pov, coef_vector = coefficient_train,
                                          stable_coef_names = coefficient_names_train, question_key = question_key)
      score_test <- scorecardtest[[2]] #Store scores for all respondents in the test set 
      
      ################# STEP 7: Predict fitted values based on the elastic-net model and create a function that maps the relationship 
      # of these fitted values vs the adjusted values that go from 0 to 100 that we created
      # Based on the sigmoid function (the one used in logit and the elastic net regression), estimate probabilities for the trainning set
      predicted_prob_train <- prediction_function(data = train_data, y = pov, glm_object = stable_fit_train,
                                                  stable_coef_names = coefficient_names_train, lambda = selected_lambda, type = "response")
      
      lookup_data <-  data.frame(cbind(score_train, predicted_prob_train)) # Construct the Lookup Table that maps scores to probabilities
      lookup_table <- as.data.frame(as.matrix(create_lookup_table(lookup_data)))  # Use the training data relationship as the basis of the lookup table
      
      ################# STEP 8: Etimate prediction errors on the test set (targetting and poverty rates)
      pred_score_pr <- prob_lookup_table(lookup_table,score_test) #These are the predicted probabilities from the transformed/simplified model we created
      test_data_pr <- cbind(test_data,pred_score_pr) # Merge model predictions with test data
      test_data_target <- cbind(test_data,score_test) #Merge test data set (with all variables with our scores (0-100)
      names(lookup_table) <- c("Predicted_Probability","Score") #Put names to the lookup_table
      names_error = c("cutoff",	"2.5%_excl",	"5%_excl",	"50%_excl",	"95%_excl",	"97.5%_excl",	"2.5%_incl",	"5%_incl",	"50%_incl",	"95%_incl",	"97.5%_incl", "obs", "zone", "povline")
      boots_ss <- rep(bootstrap_sample_size, each=19) #Vector to label the sample size of the errors calculated
      if (pov==target_base){ #Keep the test set data set to make any additional analysis on error rates
        write.dta(test_data_pr[,c(ID, "pred_score_pr")], paste(clean,"TEST_",pov,"_",nq,"q.dta", sep=""))
      }
      #Error rates for targetting (exclusion and inclusion)
      error_full <-  bootstrap_test(data_boot_test = test_data_target, y = pov,
                                    bootstrap_sample_size = bootstrap_sample_size, bootstrap_reps = bootstrap_error_reps,
                                    score = "score_test")
      error_full <- as.data.frame(cbind(error_full, boots_ss, "full", pov))
      
      #error_urban <- bootstrap_test(data_boot_test = test_data_target[test_data_target$urban==1,],
       #                             y = pov, bootstrap_sample_size = bootstrap_sample_size, bootstrap_reps = bootstrap_error_reps,
        #                            score = "score_test")
      #error_urban <- as.data.frame(cbind(error_urban, boots_ss,"urban", pov))
      
      #error_rural <- bootstrap_test(data_boot_test = test_data_target[test_data_target$urban==0,],
       #                             y = pov, bootstrap_sample_size = bootstrap_sample_size, bootstrap_reps = bootstrap_error_reps,
        #                            score = "score_test")
      #error_rural <- as.data.frame(cbind(error_rural, boots_ss, "rural", pov))
      
      colnames(targetting_error) <- colnames(error_full)
      targetting_error <- rbind(targetting_error, error_full) #Put together all 
      colnames(targetting_error) <- names_error #Plug in the correct names for every colu
      
      #Error rates (confidence intervals) for poverty rates
      names(test_data_pr[,ncol(test_data_pr)]) <- "pred_score_pr" #name the column that states the poverty probability of each ind
      
      pov_error_ci_full <- bootstrap_pov_test(data_boot_test = test_data_pr, y = pov, bootstrap_sample_size = bootstrap_error_sample_size,
                                              bootstrap_reps = bootstrap_error_reps, weight= weight_name, score_probability = "pred_score_pr")
      pov_error_ci_full <- as.data.frame(cbind(pov_error_ci_full, obs = bootstrap_error_sample_size, zone ="full", povline = pov))
      
      #pov_error_ci_urban <- bootstrap_pov_test(data_boot_test = test_data_pr[test_data_pr$urban==1,],
       #                                        y = pov, bootstrap_sample_size = bootstrap_error_sample_size, bootstrap_reps = bootstrap_error_reps,
        #                                       weight= weight_name, score_probability = "pred_score_pr")
      #pov_error_ci_urban <- as.data.frame(cbind(pov_error_ci_urban, obs = bootstrap_error_sample_size, zone ="urban", povline = pov))
      
      #pov_error_ci_rural <- bootstrap_pov_test(data_boot_test = test_data_pr[test_data_pr$urban==0,],
       #                                        y = pov, bootstrap_sample_size = bootstrap_error_sample_size, bootstrap_reps = bootstrap_error_reps,
        #                                       weight= weight_name, score_probability = "pred_score_pr")
      #pov_error_ci_rural <- as.data.frame(cbind(pov_error_ci_rural, obs = bootstrap_error_sample_size, zone ="rural", povline = pov))
      
      colnames(poverty_error) <- colnames(pov_error_ci_full) #Change names so rbind runs
      poverty_error <- rbind(poverty_error, pov_error_ci_full) #Put together all error rates
      print(paste("                     Calculated error rates for ", pov))
    }
    
    targetting_error <- targetting_error[-1,] #Take away NAs from first ob
    write.csv(targetting_error, file =  paste(results, "/Target_Errors_", nq, "q_", "ALLpovlines.csv",sep=""), col.names = T)
    poverty_error <- poverty_error[-1,] #Take away the first NA
    write.csv(poverty_error, file =  paste(results, "/PovRate_Errors_", nq, "q_", "ALLpovlines.csv",sep="") ,row.names = F , col.names = T)
    print("                   Calculated all error rates.")
    
    ################# STEP 9: Select indicators, lambda and alpha again for the WHOLE SAMPLE
    print("            Using full sample to calibrate the final model.")
    set.seed(1234)
    
    alpha_cv_error <- c(NULL)
    lambda_cv_error <- c(NULL)
    stable_fit_list <- list(NULL)
    
    for (a in alpha_i) {
      # Runs the model on a grid of lambdas and chooses the coefficients associated with the
      # lambda that minimizes the ten-fold cross-validation error. This is done "bootstrap_reps" (usually 1000)
      # times and creates a matrix with a distribution of all coefficients. The sample size of each
      # bootstrap is a fraction of the train set. We calculate a rate of appearance for each question
      # and select those questions that appeared to be used in more models.
      selected_questions_survey <- bootstrap_variable_select(data_boot = survey_data,
                                                             bootstrap_sample_fraction = boot_sample_frac, bootstrap_reps = bootstrap_size_selection,
                                                             question_key = question_key, y= target_base, numb_questions=nq, alpha = a,
                                                             weight= weight_name, penalty_vector= penalty_vector_full)
      
      #It runs the data on a set of different alphas to see which minimizes error.
      #It runs it a set of times so that lambda is not dependent of the randomnsess of the ten-fold cross-validation error.
      #The alpha that minimizes the cross validation error is chosen 
      stable_fit_model <- stable_elastic_net(data = survey_data, stable_coef = selected_questions_survey,
                                             y = target_base, input_first_col = candidate_feature_first_col,
                                             input_last_col = candidate_feature_last_col, alpha = a, weight= weight_name)
      
      stable_fit <- stable_fit_model$final_elastic_net #This keeps the last elastic net we ran (no n-fold cross validation) from a specific alpha
      cv_error <-  stable_fit_model$min_cv_error #Minimum error found for a specific alpha
      alpha_cv_error <- c(alpha_cv_error,cv_error) #Put all the errors for each alpha together
      
      stable_fit_list[[length(stable_fit_list)+1]] <- stable_fit #We store the last elastic net we ran in a list along with all the other alphas
    }
    
    # Select Elastic Net with the Optimal Alpha
    selected_stable_elastic_net <- stable_fit_list[[which.min(alpha_cv_error) +1]] #This Elastic Net is the one with the alpha that has the lowest error
    coefficient_names_survey <- c(as.vector(rownames(selected_stable_elastic_net$beta))) #Select the variables (typically 10) that will be used in the model
    optimal_alpha <- alpha_i[[which.min(alpha_cv_error)]] #Select the alpha that yielded the lowest cv error
    
    #################
    lookup <- as.data.frame(matrix(0:100, ncol=1))   #Create a NA vector where to store
    colnames(lookup) <- "Score"
    scorecard <- as.data.frame(matrix(coefficient_names_survey, ncol=1))
    colnames(scorecard) <- "stable_coef_names"
    for (pov in target) {
      print(paste("               Calibrating model for ", pov))
      # Run for every pov line now with chosen alpha
      stable_fit_survey_list <- stable_elastic_net(data = survey_data, stable_coef = coefficient_names_survey ,
                                                   y = pov, input_first_col = candidate_feature_first_col, 
                                                   input_last_col = candidate_feature_last_col, alpha = optimal_alpha,
                                                   weight= weight_name) 
      
      stable_fit_survey <- stable_fit_survey_list$final_elastic_net #This keeps the last elastic net we ran (no n-fold cross validation) 
      selected_lambda <-  stable_fit_survey_list$median_lambda #We choose the median lambda that minimizes cross validation error (we already chose alpha)
      coefficient_survey_matrix <- as.matrix(coef.glmnet(stable_fit_survey, s= selected_lambda)) #We keep the coefficient for the selected lambda
      coefficient_survey <- coefficient_survey_matrix[-1] #Store the coefficients of the model with the chosen lambda and alpha
      
      # Transforms coefficients to produce scorecard
      # Scorecards and score for the training set: substract minimum absolute score, rescales, rounds.
      scorecardsurvey <- scorecard_function(data = survey_data, y= pov,
                                            coef_vector = coefficient_survey, stable_coef_names = coefficient_names_survey,
                                            question_key = question_key)
      
      scorecard_survey <- scorecardsurvey[[1]] #Store rescaled and rounded coefficients
      score_survey <- scorecardsurvey[[2]] #Store scores for all respondents in the trainning set
      colnames(scorecard_survey) <- c("stable_coef_names", paste(pov))
      
      # Predict fitted values based on the elastic-net model and create a function that maps the relationship 
      # of these fitted values vs the adjusted values that go from 0 to 100 that we created
      # Based on the sigmoid function (the one used in logit and the elastic net regression), estimate probabilities for the trainning set
      predicted_prob_survey <- prediction_function(data = survey_data, y= pov, glm_object = stable_fit_survey,
                                                   stable_coef_names = coefficient_names_survey, lambda = selected_lambda, type = "response")
      
      lookup_data_survey <- data.frame(cbind(score_survey, predicted_prob_survey)) # Construct the Lookup Table that maps scores to probabilities
      lookup_table_survey <- as.data.frame(as.matrix(create_lookup_table(lookup_data_survey))) # Use the training data relationship as the basis of the lookup table
      
      names(lookup_table_survey) <- c(paste(pov),"Score")
      
      lookup <- merge(lookup, lookup_table_survey, by = "Score")
      scorecard <- merge(scorecard, scorecard_survey, by= "stable_coef_names")
    }
    write.csv(scorecard,  file = paste(results, "/", "Scocard_", nq, "q_", "ALLpovlines.csv", sep=""), row.names = T)
    write.csv(lookup,  file = paste(results, "/", "Lookup_table_", nq, "q_", "ALLpovlines.csv", sep=""), row.names = T)
    end_time <- Sys.time()
    print(paste("     Finished the ", nq, " question model."))
    print(start_time-end_time)    
  }
