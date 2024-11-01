#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

# ui.R

library(shiny)
library(shinythemes)
library(DT)
library(shinyBS)
library(plotly)

ui <- fluidPage(
  theme = shinytheme("cerulean"),
  
  # Title and Navigation Panel
  tabsetPanel(
    id = "main_nav",  # This ID allows switching between tabs programmatically if needed
    
    # Home Tab (Title Page)
    tabPanel("Home",
             titlePanel("Financial Metrics Analysis of Major Companies (2009-2023)"),
             
             fluidRow(
               column(12, 
                      h3("Welcome to the Financial Metrics Dashboard"),
                      p("This interactive application provides insights into the financial performance of major companies over the past decade. 
             Use the tabs above to explore trends, compare metrics, and visualize data in various forms, including line plots, bar charts, scatterplots, and more."),
                      
                      br(),
                      
                      h4("How to Use This Dashboard"),
                      tags$ul(
                        tags$li("Navigate through the tabs to view different analyses and visualizations."),
                        tags$li("Filter data by company, metric, and time range to customize the insights."),
                        tags$li("Hover over data points to see exact values and use tooltips for guidance."),
                        tags$li("In the Summary Table, select metrics to compare companies, and use the growth metrics to analyze performance over time.")
                      ),
                      
                      br(),
                      
                      h4("Project Objectives"),
                      p("This app was designed to enable users to:"),
                      tags$ul(
                        tags$li("Identify trends in financial metrics for selected companies."),
                        tags$li("Compare company performance based on key financial ratios and indicators."),
                        tags$li("Visualize data distribution across companies and metrics for deeper insights.")
                      )
               )
             )
    ),
    
    # Single Company Analysis Tab
    tabPanel("Single Company Analysis",
             sidebarPanel(
               selectInput("company", "Select Company:", 
                           choices = unique(financial_data_cleaned$Company)),
               bsTooltip("company", "Choose a company to analyze in-depth.", placement = "right"),
               
               selectInput("metric", "Select Financial Metric:", 
                           choices = c("Revenue", "Net_Income", "EPS", "Debt_Equity_Ratio", 
                                       "ROE", "ROA", "EBITDA", "Net_Profit_Margin", 
                                       "Operating_Cash_Flow", "Market_Cap_B_USD")),
               bsTooltip("metric", "Select a financial metric to plot for the chosen company.", placement = "right"),
               
               sliderInput("yearRange", "Select Year Range:", 
                           min = min(financial_data_cleaned$Year), 
                           max = max(financial_data_cleaned$Year), 
                           value = c(2010, 2020), sep = ""),
               bsTooltip("yearRange", "Adjust to filter data for a specific year range.", placement = "right"),
               
               sliderInput("rolling_window", "Rolling Window for Smoothing (Months):", 
                           min = 1, max = 12, value = 3),
               bsTooltip("rolling_window", "Set a rolling window size to smooth time-series data.", placement = "right")
             ),
             
             mainPanel(
               textOutput("selected_info"),
               plotlyOutput("metric_plot"),
               tableOutput("data_table")
             )
    ),
    
    # Comparative Analysis Tab
    tabPanel("Comparative Analysis",
             sidebarPanel(
               selectInput("companies", "Select Companies for Comparison:", 
                           choices = unique(financial_data_cleaned$Company), 
                           selected = unique(financial_data_cleaned$Company)[1:3], 
                           multiple = TRUE),
               bsTooltip("companies", "Choose multiple companies to compare across metrics.", placement = "right"),
               
               selectInput("metric", "Select Metric for Comparison:", 
                           choices = c("Revenue", "Net_Income", "EPS", "Debt_Equity_Ratio", 
                                       "ROE", "ROA", "EBITDA", "Net_Profit_Margin", 
                                       "Operating_Cash_Flow", "Market_Cap_B_USD")),
               bsTooltip("metric", "Choose a metric to compare across selected companies.", placement = "right")
             ),
             
             mainPanel(
               plotOutput("bar_chart")
             )
    ),
    
    # Combined Scatterplot and Heatmap Tab
    tabPanel("Combined Scatterplot and Heatmap",
             sidebarPanel(
               selectInput("plot_type", "Select Plot Type:", 
                           choices = c("Scatterplot", "Heatmap")),
               bsTooltip("plot_type", "Choose the type of plot to display: Scatterplot or Heatmap.", placement = "right"),
               
               # Scatterplot-specific inputs
               conditionalPanel(
                 condition = "input.plot_type == 'Scatterplot'",
                 selectInput("x_metric", "Select X-axis Metric:", 
                             choices = c("ROE", "ROA", "EBITDA", "Net_Profit_Margin")),
                 bsTooltip("x_metric", "Choose a metric for the x-axis in the scatterplot.", placement = "right"),
                 
                 selectInput("y_metric", "Select Y-axis Metric:", 
                             choices = c("ROE", "ROA", "EBITDA", "Net_Profit_Margin")),
                 bsTooltip("y_metric", "Choose a metric for the y-axis in the scatterplot.", placement = "right"),
                 
                 selectInput("companies", "Select Companies for Scatterplot:", 
                             choices = unique(financial_data_cleaned$Company), 
                             selected = unique(financial_data_cleaned$Company)[1:3], 
                             multiple = TRUE),
                 bsTooltip("companies", "Select multiple companies for scatterplot analysis.", placement = "right")
               ),
               
               # Heatmap-specific inputs
               conditionalPanel(
                 condition = "input.plot_type == 'Heatmap'",
                 selectInput("heatmap_metric", "Select Financial Metric for Heatmap:", 
                             choices = c("ROE", "ROA", "Net_Income", "EBITDA", "Revenue")),
                 bsTooltip("heatmap_metric", "Choose a metric to analyze across companies and time in the heatmap.", placement = "right"),
                 
                 selectInput("heatmap_companies", "Select Companies for Heatmap:", 
                             choices = unique(financial_data_cleaned$Company), 
                             selected = unique(financial_data_cleaned$Company)[1:5], 
                             multiple = TRUE),
                 
                 sliderInput("heatmap_yearRange", "Select Year Range for Heatmap:", 
                             min = min(financial_data_cleaned$Year), 
                             max = max(financial_data_cleaned$Year), 
                             value = c(2010, 2020), sep = "")
               )
             ),
             
             mainPanel(
               conditionalPanel(
                 condition = "input.plot_type == 'Scatterplot'",
                 plotOutput("scatter_plot")
               ),
               conditionalPanel(
                 condition = "input.plot_type == 'Heatmap'",
                 plotOutput("heatmap_plot")
               )
             )
    ),
    
    # Summary Table Tab
    tabPanel("Summary Table",
             sidebarPanel(
               selectInput("summary_companies", "Select Companies for Summary:", 
                           choices = unique(financial_data_cleaned$Company), 
                           selected = unique(financial_data_cleaned$Company)[1:3], 
                           multiple = TRUE),
               bsTooltip("summary_companies", "Choose companies to include in the summary table.", placement = "right"),
               
               selectInput("summary_metrics", "Select Metrics for Summary:", 
                           choices = c("Revenue", "Net_Income", "EPS", "ROE", "ROA", 
                                       "EBITDA", "Net_Profit_Margin"), 
                           multiple = TRUE,
                           selected = c("Revenue", "Net_Income", "ROE")),
               bsTooltip("summary_metrics", "Choose metrics to include in the summary table.", placement = "right"),
               
               numericInput("roe_threshold", "Minimum ROE (%)", value = 10),
               bsTooltip("roe_threshold", "Filter for companies with ROE above this value.", placement = "right")
             ),
             
             mainPanel(
               DTOutput("summary_table")
             )
    ),
    
    # Boxplot Tab
    tabPanel("Boxplot (Financial Metrics)",
             sidebarPanel(
               selectInput("boxplot_metric", "Select Financial Metric for Boxplot:", 
                           choices = c("ROE", "ROA", "Net_Income", "EBITDA", "Revenue")),
               bsTooltip("boxplot_metric", "Select a financial metric to view its distribution.", placement = "right"),
               
               selectInput("boxplot_companies", "Select Companies for Boxplot:", 
                           choices = unique(financial_data_cleaned$Company), 
                           selected = unique(financial_data_cleaned$Company)[1:5], 
                           multiple = TRUE),
               bsTooltip("boxplot_companies", "Select multiple companies to see their distributions.", placement = "right")
             ),
             
             mainPanel(
               plotOutput("boxplot_plot")
             )
    )
  )
)


