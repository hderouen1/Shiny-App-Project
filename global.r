# global.R

# Load necessary libraries
library(shiny)
library(ggplot2)
library(dplyr)
library(DT)

# Load the dataset that will be accessible by both ui.R and server.R
financial_data_cleaned <- read.csv("financial_data_cleaned.csv")
