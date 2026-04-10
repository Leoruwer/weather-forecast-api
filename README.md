# Weather Forecast API

This is an application created in **Ruby on Rails**.

The idea is to consume the public API from [Open-Meteo](https://open-meteo.com/) an open-source API to fetch the weather forecast of cities based on zip code or address.

---

## Technical decisions

* On how I approached the task and rationale behind my choices: [See Here](/docs/approach.md)
* On what I would improve moving foward: [See Here](/docs/improvements.md)

---

## Dependencies

* **Faraday** - Ruby Gem for HTTP API calls.
* **Webmock** - Ruby Gem to mock HTTP requests on tests.

---

## Project Structure

```text
app/
 ├─ controllers/
 │  └─ api/
 │      └─ forecasts_controller.rb
 │
 ├─ helpers/
 │  └─ cache_helper.rb
 │
 ├─ serializers/
 │  └─ forecast_serializer.rb
 │
 └─ services/
    ├─ forecasts/
    │   └─ fetch_service.rb
    ├─ geocoding_service.rb
    └─ weather_service.rb
```

---

## Module Responsibilities

* `forecast_controller.rb`:
  * Receives request with `name` as parameter
  * Validates if name is present
  * Returns a formated JSON response

* `cache_helper.rb`:
  * Handle cache keys

* `forecast_serializer.rb`:
  * Format forecast response

* `fetch_service.rb`:
  * Coordinates forecast data
  * Fetches from the Geolocation API and Weather API
  * Handle Cache
  * Normalizes the response object
  * Handle error when any request fails

* `geocoding_service.rb`:
  * Sends request to [Open-Meteo Geocoding API](https://open-meteo.com/en/docs/geocoding-api)
  * Normalizes response objects
  * Handle API failures

* `weather_service.rb`:
  * Send request to [Open-Meteo Weather API](https://open-meteo.com/en/docs)
  * Normalizes response object
  * Handle API failures

---

## Application Use

### Endpoint

```text
GET http://localhost:3000/api/forecasts
```

#### Required Parameters

```text
name: String
```

* Accepts both zip code and address as input based on the Open-Meteo's API documentation.

### Expected Responses

#### Success

```json
{
  "data": {
    "location": {
      "location_name": "String",
      "latitude": 12.3456,
      "longitude": 12.3456
    },
    "current_temperature": 12.3,
    "high_temperature": 12.3,
    "low_temperature": 12.3,
    "extended_forecast": [
      ...
      {
        "date": "String",
        "high_temperature": 12.3,
        "low_temperature": 12.3
      },
      ...
    ],
    "from_cache": false,
    "success": true
  }
}
```

#### Failure

```json
{
  "success": false,
  "error": "String"
}
```

---

## Running the Project

### Install dependencies

```bash
bundle install
```

### Run the Rails server

```bash
bundle exec rails server
```

---

## Tests

To run tests:

```bash
bundle exec rspec
```

Tests use **Webmock** to simulate the Open-Meteo API.

---

## Author

### **Leonardo Ruwer**

* [GitHub](https://github.com/Leoruwer)
* [LinkedIn](https://www.linkedin.com/in/leonardoruwer/)
