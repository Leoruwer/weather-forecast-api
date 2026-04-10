# Technical Decisions

## Approach and Rationale

My first step was looking into Open-Meteo, a well-known open-source API for Geocoding and Weather forecasts
After reading the documentation, I was able to plan on how to solve the given problem

My idea was to keep it simple, no Database, since we don't need any persistence data, and for caching we could use MemoryStore
Created the project without Database, and API-Only to avoid any unnecessary stuff, and installed Webmock and Faraday for the standard HTTP request and testing

Faraday is one of the most known gems for HTTP request, and one I had previous experiences with, same goes for Webmock

I started by creating an Endpoint, Routes, Controller and Serializer, so I can test it more easily with an App like Postman

I went step-by-step, I started with the Geocoding API, `geocoding_service.rb` so I could retrieve the location longitude and latitude, I was able to test the address and the zip code, I could also handle errors for both
After retrieving the Latidude and Longitude, I was able to do the same for the Weather forecasts `weather_service.rb`. Open-Meteo allows an easy way to get the extended forecast, so I was able to include that feature with the current temperature, same goes for min and max temperature

When both were working as expected, I would need another service to handle the responsability of calling both, `fetch_service.rb`, this way I could separete the responsabilities for each module and keep it simple

Now all I had to do is to put everything together
`forecasts_controller.rb` would be responsable for recieveing the user request and fetching the data from `fetch_service.rb`
`fetch_service.rb` would be responsable for recieveing the call from the controller, and get the data from `geocoding_service.rb` and `weather_service.rb`
With all the data I need, I was able to use the serializer and format the data in a more friendly way

When retrieving data from Open-Meteo, the current Max and Min temperature, comes in the `extended forecast` element, but that's something I didn't want, I want to make the current temperature, min and max be in the "current" element, since it's the forecast for today. So what I had to do is, remove the first element from the `extended forecast` (today), and move it to the "current" and remove the empty index from there
This way the API handles the logic for which one is today, and which one is for the next week, and the front-end app would be able to show that without any logic behind it
So I can return the weather forecast in a clean way, more organized and easy to handle for a *future front-end app*

When I had everything in order, tested, I started implementing the Cache
When reading the exercise, I noticed some inconsistency for the Cache, one document said 15 minutes, another said 30 minutes, so I went it the latter
When implementing the cache, I had 2 requests I could cache

1. Geocoding API
2. Weather API

My first solution was to cache the Weather API for 30 minutes. However, this solution still needs to make 1 requests, and we want to avoid that
So my second solution, was a 2-step cache system
The first step: creates a cache for the user input, for example: `10001` and cache that for geocode: `geocode:10001`, so if any other user requests the weather for that Zip Code, the app will cache the latitude and longitude for 30 minutes, avoiding a request.
The second step: creates a cache for the weather response, for example: `forecast:40.6800:-40.6800`, this way, we are able to cached it with the coordinates

Why I went this way?

- If the first users looks up the weather forecast for `New York`, it will cache: `geocode:newyork` and also cache the coordinates: `forecast:40.6800:-40.6800`
- If the second users looks up the weather forecast for `10001`, the New York zip code, it will cache: `geocode:10001` and hit the second cahce for: `forecast:40.6800:-40.6800`

Even with different inputs, we are able to avoid one request
Even tho I wasn't able to think of a better solution for these cenarios, I believe this is the better approach for the way we handle the inputs, acceppting both address and zip codes

And for generating the cache keys, I decided to create the `cache_helper.rb` to handle the logic behind the keys name
