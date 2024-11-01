#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

# server.R

library(shiny)
library(ggplot2)
library(dplyr)
library(DT)
library(plotly)
library(zoo)
library(reshape2)

# Server logic
server <- function(input, output) {
  
  # Filter data based on selected company and year range for line plot
  filtered_data <- reactive({
    financial_data_cleaned %>%
      filter(Company == input$company & Year >= input$yearRange[1] & Year <= input$yearRange[2])
  })
  
  # Display selected company and metric information
  output$selected_info <- renderText({
    paste("Company:", input$company, "| Metric:", input$metric)
  })
  
  # Line plot with rolling averages and tooltips
  output$metric_plot <- renderPlotly({
    plot_data <- filtered_data() %>%
      arrange(Year)
    
    # Calculate rolling average
    plot_data$Rolling_Metric <- zoo::rollapply(plot_data[[input$metric]], 
                                               width = input$rolling_window, 
                                               FUN = mean, 
                                               fill = NA, 
                                               align = "right")
    
    # Plot using plotly for tooltips
    p <- ggplot(plot_data, aes(x = Year, y = Rolling_Metric)) +
      geom_line(color = "blue") +
      geom_point(color = "darkblue") +
      labs(title = paste(input$metric, "Trend for", input$company, "(Smoothed)"), 
           x = "Year", y = input$metric) +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Display filtered data in a table
  output$data_table <- renderTable({
    filtered_data() %>%
      select(Year, Company, input$metric) %>%
      arrange(Year)
  })
  
  # Bar chart to compare financial metrics across companies
  output$bar_chart <- renderPlot({
    data_aggregated <- financial_data_cleaned %>%
      filter(Company %in% input$companies & Year >= input$yearRange[1] & Year <= input$yearRange[2]) %>%
      group_by(Company) %>%
      summarize(SelectedMetric = sum(get(input$metric), na.rm = TRUE))
    
    ggplot(data_aggregated, aes(x = Company, y = SelectedMetric, fill = Company)) +
      geom_bar(stat = "identity") +
      labs(title = paste("Comparative", input$metric, "for Selected Companies"), 
           x = "Company", y = input$metric) +
      theme_minimal() +
      scale_fill_brewer(palette = "Set3")
  })
  
  # Scatterplot for comparing x and y metrics
  output$scatter_plot <- renderPlot({
    req(input$plot_type == "Scatterplot", input$x_metric, input$y_metric)  # Only proceed if Scatterplot is selected
    
    scatter_data <- financial_data_cleaned %>%
      filter(Company %in% input$companies & Year >= input$yearRange[1] & Year <= input$yearRange[2])
    
    ggplot(scatter_data, aes(x = get(input$x_metric), y = get(input$y_metric), color = Company)) +
      geom_point(size = 3) +
      labs(title = paste(input$x_metric, "vs", input$y_metric), 
           x = input$x_metric, y = input$y_metric) +
      theme_minimal() +
      scale_color_brewer(palette = "Set2")
  })
  
  # Heatmap for financial ratios across companies
  output$heatmap_plot <- renderPlot({
    req(input$plot_type == "Heatmap", input$heatmap_metric)  # Only proceed if Heatmap is selected
    
    heatmap_data <- financial_data_cleaned %>%
      filter(Company %in% input$heatmap_companies & 
               Year >= input$heatmap_yearRange[1] & Year <= input$heatmap_yearRange[2]) %>%
      select(Company, Year, input$heatmap_metric)
    
    heatmap_data_wide <- dcast(heatmap_data, Year ~ Company, value.var = input$heatmap_metric)
    
    ggplot(melt(heatmap_data_wide, id.vars = 'Year'), aes(x = variable, y = Year, fill = value)) +
      geom_tile(color = "white") +
      scale_fill_gradient(low = "lightblue", high = "red") +
      labs(x = "Company", y = "Year", title = paste("Heatmap of", input$heatmap_metric)) +
      theme_minimal()
  })
  
  # Summary table with conditional formatting for growth rates
  output$summary_table <- renderDT({
    req(input$summary_metrics, input$companies)
    
    # Create summary data
    summary_data <- financial_data_cleaned %>%
      filter(Company %in% input$companies) %>%
      filter(Year >= input$yearRange[1] & Year <= input$yearRange[2]) %>%
      group_by(Company) %>%
      summarise(across(all_of(input$summary_metrics), list(
        Mean = ~mean(., na.rm = TRUE),
        Min = ~min(., na.rm = TRUE),
        Max = ~max(., na.rm = TRUE),
        Growth = ~((last(.) - first(.)) / first(.)) * 100
      ))) %>%
      ungroup()
    
    # Round all numeric columns to 2 decimal places
    summary_data <- summary_data %>%
      mutate(across(where(is.numeric), ~round(., 2)))
    
    # Create the datatable
    datatable(summary_data,
              options = list(
                pageLength = 5,
                scrollX = TRUE,
                dom = 'rtip'
              ),
              rownames = FALSE) %>%
      formatStyle(
        names(summary_data)[grep("Growth", names(summary_data))],
        backgroundColor = styleInterval(c(0), c('pink', 'lightgreen')),
        color = styleInterval(c(0), c('red', 'darkgreen'))
      )
  })
  
  # Boxplot for financial metrics across companies
  output$boxplot_plot <- renderPlot({
    boxplot_data <- financial_data_cleaned %>%
      filter(Company %in% input$boxplot_companies & 
               Year >= input$yearRange[1] & Year <= input$yearRange[2]) %>%
      select(Company, input$boxplot_metric)
    
    ggplot(boxplot_data, aes(x = Company, y = get(input$boxplot_metric))) +
      geom_boxplot(fill = "lightblue") +
      labs(title = paste("Boxplot of", input$boxplot_metric, "for Selected Companies"), 
           x = "Company", y = input$boxplot_metric) +
      theme_minimal()
  })
}



# Run the app
#shinyApp(ui = ui, server = server)

