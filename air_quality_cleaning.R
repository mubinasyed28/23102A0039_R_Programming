##############################################################
# Beijing Air Quality Data Cleaning
# Reference R Script
##############################################################

#############################
# TASK 1
# Import and Inspect Dataset
#############################

file_name <- "PRSA_Data_Aotizhongxin_20130301-20170228.csv"

air_data <- tryCatch({

    data <- read.csv(file_name)

    cat("Dataset Loaded Successfully!\n\n")

    cat("First 6 Records:\n")
    print(head(data))

    cat("\nStructure:\n")
    str(data)

    cat("\nRows and Columns:\n")
    print(dim(data))

    cat("\nContains Missing Values:\n")
    print(any(is.na(data)))

    cat("\nTotal Missing Values:\n")
    print(sum(is.na(data)))

    data

}, error=function(e){

    message <- conditionMessage(e)

    if(grepl("cannot open", message)) {
        cat("Error: File cannot be opened or not found.\n")
    } else {
        cat("Error: Incorrect file format.\n")
    }

    NULL
})

if(is.null(air_data))
{
    stop("Program terminated because dataset could not be loaded.")
}


##################################
# TASK 2
# NA, NULL and NaN Demonstration
##################################

temperature <- c(28,30,NA,32)

missing_object <- NULL

undefined_value <- 0/0

cat("\n----- NA Example -----\n")
print(temperature)
print(is.na(temperature))

cat("\n----- NULL Example -----\n")
print(missing_object)
print(is.null(missing_object))

cat("\n----- NaN Example -----\n")
print(undefined_value)
print(is.nan(undefined_value))


############################################
# TASK 3
# User Defined Missing Summary Function
############################################

missing_summary <- function(df, variables){

    result <- data.frame(
        Variable=character(),
        Total_Records=integer(),
        Missing_Values=integer(),
        Missing_Percentage=double(),
        stringsAsFactors=FALSE
    )

    for(v in variables){

        total <- nrow(df)

        missing <- sum(is.na(df[[v]]))

        percent <- (missing/total)*100

        result <- rbind(result,
                        data.frame(
                            Variable=v,
                            Total_Records=total,
                            Missing_Values=missing,
                            Missing_Percentage=round(percent,2)
                        ))

        if(percent>20){
            warning(paste(v,"contains more than 20% missing values"))
        }

    }

    return(result)

}

selected_variables <- c("PM2.5","PM10","SO2","NO2","TEMP","WSPM","wd")

summary_before <- missing_summary(air_data,selected_variables)

cat("\nMissing Summary:\n")
print(summary_before)


###############################################
# TASK 4
# Pollution Ratio
###############################################

air_data$pollution_ratio <- air_data$PM2.5 / air_data$PM10

cat("\nNA Count:\n")
print(sum(is.na(air_data$pollution_ratio)))

cat("\nNaN Count:\n")
print(sum(is.nan(air_data$pollution_ratio)))

cat("\nInfinite Count:\n")
print(sum(is.infinite(air_data$pollution_ratio)))

air_data$pollution_ratio[
    is.nan(air_data$pollution_ratio) |
    is.infinite(air_data$pollution_ratio)
] <- NA


###########################################
# TASK 5
# Median Replacement Using Loop
###########################################

numeric_variables <- c(
    "PM2.5",
    "PM10",
    "SO2",
    "NO2",
    "TEMP",
    "WSPM"
)

missing_before_numeric <- c()

for(v in numeric_variables){

    if(v %in% names(air_data)){

        before <- sum(is.na(air_data[[v]]))

        median_value <- median(air_data[[v]],na.rm=TRUE)

        air_data[[v]][is.na(air_data[[v]])] <- median_value

        after <- sum(is.na(air_data[[v]]))

        missing_before_numeric[v] <- before

        cat("\n-----------------------------\n")
        cat("Variable :",v,"\n")
        cat("Missing Before :",before,"\n")
        cat("Median :",median_value,"\n")
        cat("Missing After :",after,"\n")

    }

}


##########################################
# TASK 6
# Mode Function
##########################################

calculate_mode <- function(x){

    x <- x[!is.na(x)]

    unique_values <- unique(x)

    unique_values[
        which.max(tabulate(match(x,unique_values)))
    ]

}

before_wd <- sum(is.na(air_data$wd))

mode_wd <- calculate_mode(air_data$wd)

air_data$wd[is.na(air_data$wd)] <- mode_wd

after_wd <- sum(is.na(air_data$wd))

cat("\nWind Direction Missing Before :",before_wd,"\n")
cat("Wind Direction Mode :",mode_wd,"\n")
cat("Wind Direction Missing After :",after_wd,"\n")


###########################################
# TASK 7
# clean_variable()
###########################################

clean_variable <- function(df,var_name){

    tryCatch({

        if(!(var_name %in% names(df)))
            stop("Variable does not exist.")

        if(!is.numeric(df[[var_name]]))
            stop("Variable is not numerical.")

        if(all(is.na(df[[var_name]])))
            stop("Variable contains only missing values.")

        med <- median(df[[var_name]],na.rm=TRUE)

        if(is.na(med))
            stop("Median cannot be calculated.")

        df[[var_name]][is.na(df[[var_name]])] <- med

        return(df[[var_name]])

    },error=function(e){

        cat("Error:",conditionMessage(e),"\n")

        return(NULL)

    })

}

test <- clean_variable(air_data,"PM2.5")

test2 <- clean_variable(air_data,"wd")

test3 <- clean_variable(air_data,"XYZ")


#############################################
# TASK 8
# Comparison Table
#############################################

summary_after <- missing_summary(air_data,selected_variables)

comparison <- data.frame(

    Variable=selected_variables,

    Missing_Before=summary_before$Missing_Values,

    Missing_After=summary_after$Missing_Values,

    Values_Replaced=
        summary_before$Missing_Values-
        summary_after$Missing_Values

)

cat("\nComparison Table:\n")
print(comparison)

cat("\nInterpretation:\n")

if(all(comparison$Missing_After==0)) {
    cat("All selected missing values were handled successfully.\n")
} else {
    cat("Some variables still contain missing values.\n")
}


###########################################
# TASK 9
# Bar Chart
###########################################

before_values <- comparison$Missing_Before

after_values <- comparison$Missing_After

png("missing_values_chart.png", width=800, height=600)

barplot(

    rbind(before_values,after_values),

    beside=TRUE,

    names.arg=comparison$Variable,

    col=c("red","green"),

    main="Missing Values Before and After Cleaning",

    xlab="Variables",

    ylab="Number of Missing Values"

)

legend(

    "topright",

    legend=c("Before","After"),

    fill=c("red","green")

)

dev.off()


############################################
# TASK 10
# Export Cleaned Dataset
############################################

write.csv(

    air_data,

    "cleaned_air_quality_data.csv",

    row.names=FALSE

)

cat("\nCleaned dataset exported successfully!\n")