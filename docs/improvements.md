# Improvements

## Things I would improve

* Better Caching

  * Change from MemoryStore to Redis for a more robust and production-ready environment
  * Separete cache duration depending on Geocode or Weather data, e.g.: 1 day for Geocode, 30 minutes for Weather

* Improve error handling

  * More precise error messages depending on what failed
  * Handle timeouts, malformed responses, unexpected payloads

* Rate limit/Protection

  * Add rate limit to protect endpoint from excessive requests
