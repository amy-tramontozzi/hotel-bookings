library(readxl)
library(tidyverse)
library(writexl)
library(dplyr)
library(lubridate)

#Bookings data
bookings <- read.csv("hotel_bookings.csv")

bookings <- filter(bookings, hotel == "Resort Hotel")

# Convert month names to numbers
bookings$arrival_date_month <- match(bookings$arrival_date_month, month.name)

bookings$reservation_status <- as.factor(bookings$reservation_status)

bookings$agent[bookings$agent == "NULL"] <- NA
bookings$agent <- as.integer(bookings$agent)

# Create the date column
bookings$arrival_date <- as.Date(
  paste(
    bookings$arrival_date_year,
    sprintf("%02d", bookings$arrival_date_month),
    sprintf("%02d", bookings$arrival_date_day_of_month),
    sep = "-"
  )
)

#Hotel data
hotel <- bookings %>% select(arrival_date, is_canceled, lead_time, reserved_room_type, assigned_room_type, market_segment, distribution_channel,
                    reservation_status, deposit_type, meal, adults, children, babies, booking_changes, required_car_parking_spaces,
                    total_of_special_requests, adr, reservation_status_date)

bookings <- bookings %>%
  mutate(
    cancellation_lead_time = if_else(
      reservation_status == "Canceled",
      as.numeric(difftime(reservation_status_date, arrival_date, units = "days")),
      NA_real_  # Assign NA for non-canceled reservations
    )
  )

set.seed(13)  # For reproducibility

# Define probabilities for each number (heavily biased towards 1 and 2)
probabilities <- c(0.4, 0.3, 0.15, 0.1, 0.04, 0.01)

# Randomly assign numbers with weighted probabilities
bookings$duration_category <- sample(1:6, size = nrow(bookings), replace = TRUE, prob = probabilities)

bookings <- bookings %>%
  mutate(
    cancellation_lead_time_category = case_when(
      cancellation_lead_time <= -300 ~ "Very Early",
      cancellation_lead_time <= -112.458 ~ "Early",
      cancellation_lead_time <= -51.417  ~ "Moderate",
      cancellation_lead_time <= -17.458  ~ "Late",
      cancellation_lead_time <= -0.417   ~ "Last Minute"
    )
  )

bookings <- bookings %>%
  mutate(lead_time_group = case_when(
    lead_time <= 20  ~ 1,
    lead_time <= 40  ~ 2,
    lead_time <= 100 ~ 3,
    lead_time <= 200 ~ 4,
    lead_time <= 400 ~ 5,
    TRUE             ~ 6
  ))

bookings <- bookings %>%
  mutate(adr_group = case_when(
    adr <= 50    ~ 1,    # 1st Quartile
    adr <= 75    ~ 2,    # Median
    adr <= 125   ~ 3,    # 3rd Quartile
    adr <= 508   ~ 4,    # Max
    adr < -0  ~ 0,    # Min (if relevant)
    TRUE               ~ 5     # Beyond max (if applicable)
  ))


hotel <- bookings %>%
  select(is_canceled, reservation_status, deposit_type, adults, children, babies, booking_changes,
         adr_group, lead_time_group, cancellation_lead_time_category, duration_category) %>%
  distinct(is_canceled, reservation_status, deposit_type, adults, children, babies, booking_changes,
           adr_group, lead_time_group, cancellation_lead_time_category, duration_category)

hotel$bookingID <- 1:nrow(hotel)

# Perform the join based on the grouping variables
bookings <- bookings %>%
  left_join(hotel %>%
              select(is_canceled, reservation_status, deposit_type, adults, children, babies, booking_changes,
                     adr_group, lead_time_group, cancellation_lead_time_category, duration_category, bookingID),
            by = c("is_canceled", "reservation_status", "deposit_type", "adults", "children", "babies", 
                   "booking_changes", "adr_group", "lead_time_group", "cancellation_lead_time_category", "duration_category"))

write_csv(hotel, "hotel.csv")

# Customer data
customer <- bookings %>%
  select(is_repeated_guest, previous_cancellations, previous_bookings_not_canceled, customer_type)

library(randomNames)

# Generate random names
customer$name <- randomNames(n = nrow(customer), gender = "both")

num_unique <- floor(0.9 * nrow(customer))

unique_names <- sample(customer$name, num_unique, replace = FALSE)

repeated_names <- sample(customer$name, nrow(customer) - num_unique, replace = TRUE)

customer$name <- c(unique_names, repeated_names)

customer$name <- sample(customer$name)

customer$name <- as.factor(customer$name)

customer$name <- gsub(",", "", customer$name)


customer$customerLastName <- str_split_fixed(customer$name, " ", 2)[,1]
customer$customerName <- str_split_fixed(customer$name, " ", 2)[,2]

library(dplyr)

# Ensure unique names in the customer data frame
customer <- customer %>%
  group_by(name) %>%
  slice(1) %>%  # Keep the first occurrence of each name
  ungroup()

# Lists of country codes and area codes
country_codes <- c("+1", "+44", "+61", "+49", "+91")  # US, UK, Australia, Germany, India

# Function to generate random phone numbers with random country and area codes
generate_phone_number <- function() {
  country_code <- sample(country_codes, 1)  # Randomly select a country code
  area_code <- sprintf("%03d", sample(100:999, 1))  # Random area code
  central_office_code <- sprintf("%03d", sample(100:999, 1))
  line_number <- sprintf("%04d", sample(1000:9999, 1))
  paste(country_code, area_code, central_office_code, line_number, sep = "-")
}

# Generate phone numbers for each unique customer name
customer <- customer %>%
  mutate(phone = sapply(name, function(x) generate_phone_number()))

country_map <- c("+1" = "United States", 
                 "+44" = "United Kingdom", 
                 "+61" = "Australia", 
                 "+49" = "Germany", 
                 "+91" = "India")

# Extract the country code from the phone number (assuming it's the first part before "-")
customer <- customer %>%
  mutate(country_code = sub("-.*", "", phone),  # Extract country code
         country = country_map[country_code])   # Map to country name

customer$customerid <- 1:nrow(customer)

bookings$customerID <- sample(customer$customerid, size = nrow(bookings), replace = TRUE)

customer <- customer %>% select(c(-name, -country_code))

write_csv(customer, "customer.csv")

#employee table
employee <- bookings %>%
  select(agent)

employee <- employee %>%
  distinct(agent)

# Employee table
employee$name <- randomNames(n = nrow(employee), gender = "both")

employee$name <- as.factor(employee$name)

employee$name <- gsub(",", "", employee$name)

employee$employeeLastName <- str_split_fixed(employee$name, " ", 2)[,1]
employee$employeeName <- str_split_fixed(employee$name, " ", 2)[,2]

employee[employee == "NULL"] <- NA

employee <- employee %>% filter(!is.na(agent))

employee <- employee %>%
  select(-name)

write_csv(employee, "employee.csv", col_names = TRUE)

# Weather table
weather <- read_csv("lisbon_weather_2015_2017.csv")

weather_aggregated <- weather %>%
  group_by(description) %>%
  summarise(
    tempmax = mean(tempmax, na.rm = TRUE),
    tempmin = mean(tempmin, na.rm = TRUE),
    temp = mean(temp, na.rm = TRUE),
    feelslikemax = mean(feelslikemax, na.rm = TRUE),
    feelslikemin = mean(feelslikemin, na.rm = TRUE),
    feelslike = mean(feelslike, na.rm = TRUE),
    dew = mean(dew, na.rm = TRUE),
    humidity = mean(humidity, na.rm = TRUE),
    precip = mean(precip, na.rm = TRUE),
    precipprob = mean(precipprob, na.rm = TRUE),
    precipcover = mean(precipcover, na.rm = TRUE),
    windgust = mean(windgust, na.rm = TRUE),
    windspeed = mean(windspeed, na.rm = TRUE),
    winddir = mean(winddir, na.rm = TRUE),
    sealevelpressure = mean(sealevelpressure, na.rm = TRUE),
    cloudcover = mean(cloudcover, na.rm = TRUE),
    visibility = mean(visibility, na.rm = TRUE),
    solarradiation = mean(solarradiation, na.rm = TRUE),
    solarenergy = mean(solarenergy, na.rm = TRUE),
    uvindex = mean(uvindex, na.rm = TRUE),
    moonphase = mean(moonphase, na.rm = TRUE)
  )

weather_aggregated$weatherid <- 1:nrow(weather_aggregated)
weather <- merge(weather, weather_aggregated, by =  "description")
bookings <- merge(weather, bookings, by.x = "datetime", by.y = "arrival_date")
bookings <- bookings[-2:-54]

write_csv(weather_aggregated, "weather.csv", col_names = TRUE)

# Concert data
concerts <- read_excel('lisbon_concert_data.xlsx')

concerts$Date <- as.Date(concerts$Date, format = "%d-%b-%y")
concerts$`Artist(s)` <- as.factor(concerts$`Artist(s)`)
concerts$Venue <- as.factor(concerts$Venue)

concerts <- concerts %>%
  separate_rows(`Artist(s)`, sep = " / ")

venue_map <- c(
  "Antonio Zambujo / Miguel Araujo at Coliseu Dos Recreios" = "Coliseu dos Recreios",
  "Coliseu de Lisboa" = "Coliseu dos Recreios",
  "Aula Magna, Universidade de Lisboa" = "Aula Magna",
  "Cinema São Jorge" = "Cine-Teatro Sao Jorge",
  "Centro Cultural de Belem" = "CCB",
  "Culturgest Theater" = "Culturgest",
  "Estúdio Time Out" = "Estudio Time Out",
  "Centro Cultural De Belém" = "CCB",
  "Galeria Ze Dos Bois" = "Galeria ZDB",
  "Galeria Zé Dos Bois" = "Galeria ZDB",
  "LAV - Lisboa Ao Vivo" = "LAV - Lisboa ao Vivo",
  "Lisboa Ao Vivo (LaV)" = "LAV - Lisboa ao Vivo",
  "Lisboa Ao Vivo" = "LAV - Lisboa ao Vivo",
  "Lux Club" = "Lux",
  "Lux Fragil" = "Lux",
  "Lux Frágil" = "Lux",
  "LXFactory" = "LX Factory",
  "MusicBox" = "Music Box",
  "Passeio Marítimo de Algés" = "Passeio Maritimo de Alges",
  "RCA Club" = "RCA",
  "Rock in Rio Lisboa" = "Rock in Rio",
  "Rock In Rio Lisboa" = "Rock in Rio",
  "Rock in Rio Lisboa 2016" = "Rock in Rio",
  "Rock In Rio Lisboa 2016" = "Rock in Rio",
  "Sala Tejo - Meo Arena" = "Meo Arena",
  "Sala Tejo- Meo Arena" = "Meo Arena",
  "Sala Tejo, Altice Arena" = "Altice Arena",
  "Sala Tejo - Pavilhão Atlântico" = "Pavilhão Atlântico",
  "Super Bock Super Rock 2016" = "SuperBock Super Rock",
  "Time Out Market" = "Time Out Studio",
  "Vodafone Mexefest" = "Vodafone Mexecest Grounds",
  "Vodafone Mexefest Grounds" = "Vodafone Mexecest Grounds"
)

concerts <- concerts %>%
  mutate(
    Venue = case_when(
      Venue %in% names(venue_map) ~ venue_map[Venue],
      TRUE ~ Venue  # Keep original value if not in `venue_map`
    )
  )

concerts$`Artist(s)` <- iconv(concerts$`Artist(s)`, from = "UTF-8", to = "ASCII", sub = "")
concerts$Venue <- iconv(concerts$Venue, from = "UTF-8", to = "ASCII", sub = "")

concerts <- concerts %>%
  filter(Venue != "-")


# Step 1: Extract unique artist names into a new dataframe
artist <- data.frame(name = unique(concerts$`Artist(s)`))

# Step 2: Define genres
genres <- c("Pop", "Rap", "Rock", "Jazz", "Classical", "Hip-Hop", "Country", "Electronic", "Reggae", "Blues", "Metal")

# Step 3: Randomly assign genres to each artist
artist$genre <- sample(genres, nrow(artist), replace = TRUE)

artist$age <- sample(18:70, nrow(artist), replace = TRUE)


artist$artistid <- 1:nrow(artist)

to_merge <- artist %>%
  select(name, artistid)

concerts <- left_join(concerts, to_merge, by = c("Artist(s)" = "name"))

write.csv(artist, "artist.csv", fileEncoding = "UTF-8")

# Venue table

venue <- data.frame(name = unique(concerts$Venue))

venue$capacity <- sample(50:500000, nrow(venue), replace = TRUE)

venue$name <- iconv(venue$name, from = "UTF-8", to = "ASCII", sub = "")

venue$venueid <- 1:nrow(venue)

venue_merge <- venue %>%
  select(name, venueid)

concerts <- left_join(concerts, venue_merge, by = c("Venue" = "name"))

write_csv(venue, "venue.csv", col_names = TRUE)

concerts <- concerts %>%
  group_by(Date) %>%
  slice_head(n = 1) 

concerts <- concerts %>% select(Date, artistid, venueid)
concerts$concertid <- 1:nrow(concerts)

write_csv(concerts, "concerts.csv")

bookings <- left_join(bookings, concerts, by = c("datetime" = "Date"))


# Define condition based on some relevant criteria (e.g., check if concertid is not NA or is valid)
condition <- !is.na(bookings$concertid)  # Adjust based on what you need

# Initialize attended_concert with 0
bookings$attended_concert <- 0

# Only apply random sampling to rows that meet the condition
bookings$attended_concert[condition] <- sample(
  c(0, 1), 
  sum(condition),  # This ensures the sample size matches the number of TRUE values in `condition`
  replace = TRUE, 
  prob = c(0.9, 0.1)
)

trips <- bookings %>%
  select(datetime, weatherid, agent, bookingID, artistid, venueid, concertid, attended_concert, customerID)

trips$artistid[is.na(trips$artistid)] <- 0
trips$agent[is.na(trips$agent)] <- 0
trips$concertid[is.na(trips$concertid)] <- 0
trips$venueid[is.na(trips$venueid)] <- 0

write_csv(trips, "trips.csv")


ggplot(bookings, aes(x = adr_group, y = lead_time_group, fill = is_canceled)) +
  geom_tile() +
  scale_fill_gradient(low = "blue", high = "red") +
  labs(
    title = "Heatmap of Cancellation Rates by Lead Time and ADR",
    x = "ADR Bin",
    y = "Lead Time Bin"
  ) +
  theme_minimal()

cancellation_summary <- bookings %>%
  group_by(weatherid) %>%
  summarize(total_cancellations = sum(is_canceled)) %>%
  arrange(desc(total_cancellations))

ggplot(cancellation_summary, aes(x = reorder(weatherid, -total_cancellations), y = total_cancellations)) +
  geom_bar(stat = "identity", fill = "tomato") +
  coord_flip() + # Flip the coordinates for better visualization
  labs(
    title = "Weather Keys Associated with Cancellations",
    x = "",
    y = "Total Cancellations"
  ) +
  theme_minimal()

weather_table <- weather_aggregated %>%
  group_by(weatherid) %>%
  select(
    weatherid,
    description, # Take the first unique description
    temp, # Average temperature
    precip
  )

weather_table <- weather_table %>%
  rename(
    WeatherID = weatherid,
    Description = description,
    `Average Temperature` = temp,
    `Average Precipitation Level` = precip
  ) %>%
  arrange(WeatherID)  # Sort for better visualization


library(kableExtra)
kable(weather_table, "html", caption = "Weather Keys with Associated Data") %>%
  kable_styling(full_width = TRUE, bootstrap_options = c("striped", "hover", "condensed"))