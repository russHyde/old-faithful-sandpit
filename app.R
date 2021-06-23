#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(magrittr)
library(ggplot2)
library(ggpattern) # needs install from GH (remotes)
library(palmerpenguins) # needs install from CRAN

or_else = function(x, default) {
  stopifnot(is.character(x))
  if (x == "") default else x
}

api_key = Sys.getenv("API_KEY") %>% or_else("DEFAULT_VALUE")

plot_patterns = function() {
  if (!requireNamespace("ggpattern")) {
    stop("require {ggpattern}")
  }
  df = data.frame(
    level = factor(c("a", "b", "c", "d")),
    outcome = c(2.3, 1.9, 3.2, 1)
  )

  ggplot2::ggplot(df) +
    ggpattern::geom_col_pattern(
      ggplot2::aes(level, outcome, pattern_fill = level),
      pattern = "stripe",
      fill    = "white",
      colour  = "black"
    ) +
    ggplot2::theme_bw(18) +
    ggplot2::theme(legend.position = "none") +
    ggplot2::labs(
      title = "ggpattern::geom_pattern_col()",
      subtitle = "pattern = 'stripe'"
    ) +
    ggplot2::coord_fixed(ratio = 1 / 2)
}

plot_faithful = function(n_bins) {
  # generate bins based on input$bins from ui.R
  x = faithful[, 2]
  bins = seq(min(x), max(x), length.out = n_bins + 1)

  # draw the histogram with the specified number of bins
  hist(x, breaks = bins, col = "darkgray", border = "white")
}

# Define UI for application that draws a histogram
ui = fluidPage(

  # Application title
  titlePanel("Old Faithful Geyser Data"),

  # Sidebar with a slider input for number of bins
  sidebarLayout(
    sidebarPanel(
      sliderInput("bins",
        "Number of bins:",
        min = 1,
        max = 50,
        value = 30
      ),
      textOutput("api_key")
    ),

    # Show a plot of the generated distribution
    mainPanel(
      plotOutput("dist_plot"),
      plotOutput("pattern_plot"),
      plotOutput("penguin_plot")
    )
  )
)

plot_penguins = function() {
  flipper_hist = ggplot2::ggplot(
    data = penguins,
    ggplot2::aes(x = flipper_length_mm)
  ) +
    ggplot2::geom_histogram(
      ggplot2::aes(fill = species),
      alpha = 0.5,
      position = "identity"
    ) +
    ggplot2::scale_fill_manual(values = c("darkorange", "purple", "cyan4")) +
    ggplot2::theme_minimal() +
    ggplot2::labs(
      x = "Flipper length (mm)",
      y = "Frequency",
      title = "Penguin flipper lengths"
    )

  flipper_hist
}

# Define server logic required to draw a histogram
server = function(input, output) {
  output$api_key = renderText(paste0("API_KEY: ", api_key))
  output$dist_plot = renderPlot({
    plot_faithful(n_bins = input$bins)
  })
  output$pattern_plot = renderPlot({
    plot_patterns()
  })
  output$penguin_plot = renderPlot({
    plot_penguins()
  })
}

# Run the application
shinyApp(ui = ui, server = server)
