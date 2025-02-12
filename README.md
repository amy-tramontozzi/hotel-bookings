# Hotel Bookings Database Development & Predictive Cancellation Modelling

## Overview
The objective of this project is to create and store a dataset that can be used to predict hotel booking cancellations for a hotel in Lisbon, utilizing data from multiple sources, including weather, customer, and events.

## Contents
- **Data Files**: Includes all compiled datasets used in the analysis.
- **`clean.R`**: Scripts to clean, merge, and preprocess the datasets.
- **`hm_dim_ddl.sql`**: Defines the schema and creates the fact and dimension tables for the dataset, including tables such as Bookings_Fact, Customers, Hotels, Weather, and Events.
- **`hm_dim_ddl.sql`**: Loads cleaned data into the Snowflake schema using SQL INSERT INTO statements, ensuring that the data is properly populated in the respective tables.
- **`Lisbon weather.ipynb`**: Scrapes weather using OpenWeather's public API in Juyter Notebook.
