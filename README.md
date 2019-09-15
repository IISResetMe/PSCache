# PSCache
Generic PowerShell cache implementation

----

## What is PSCache?

PSCache grew out of a need to abstract away a hashtable-based "caching" scheme that I personally found myself implementing over and over again. PSCache transparently caches the results from previous queries using a custom `fetcher` - a scriptblock that'll retrieve a value from elsewhere based on a single parameter.

Here's a simple example using `PSCache` as a transparent store for results returned from `Get-ADUser`:

```powershell
Import-Module PSCache
$ADUserCache = New-PSCache -Fetcher { Get-ADUser $_ -Properties manager,title,employeeId }

# Fetch the user "jdoe" - this first cache-miss will cauce PSCache to call the `$Fetcher` scriptblock once and return the result
$ADUserCache.Get('jdoe')

# Fetch the user "jdoe" again - this time he'll be returned directly from the cache
$ADUserCache.Get('jdoe')
```

## Which eviction policies are supported?

PSCache version 0.1.1 comes with 3 optional eviction policy implementations:

### Least Recently Used (LRU)

Simple LRU policy which evicts the least recently cached entry
```powershell
# Create a cache for URL page titles
$PageTitleCache = New-PSCache { param($url) (Invoke-WebRequest $url).title } -EvictionPolicy LRU -Capacity 3

# Grab a few url page titles
$PageTitleCache.Get('https://google.com')          # cache miss, cache count = 1
$PageTitleCache.Get('https://github.com')          # cache miss, cache count = 2
$PageTitleCache.Get('https://google.com')          # cache hit
$PageTitleCache.Get('https://stackoverflow.com')   # cache miss, cache count = 3
$PageTitleCache.Get('https://bing.com')            # cache miss, cache count = 3, 'https://github.com' evicted
$PageTitleCache.Get('https://github.com')          # cache miss, cache count = 3, 'https://google.com' evicted
$PageTitleCache.Get('https://google.com')          # cache miss, cache count = 3, 'https://stackoverflow.com' evicted
```

### Most Recently Used (MRU)

Simple MRU policy which evicts the most recently cached entry
```powershell
# Create a cache for URL page titles
$PageTitleCache = New-PSCache { param($url) (Invoke-WebRequest $url).title } -EvictionPolicy MRU -Capacity 3

# Grab a few url page titles
$PageTitleCache.Get('https://google.com')          # cache miss, cache count = 1
$PageTitleCache.Get('https://github.com')          # cache miss, cache count = 2
$PageTitleCache.Get('https://google.com')          # cache hit
$PageTitleCache.Get('https://stackoverflow.com')   # cache miss, cache count = 3
$PageTitleCache.Get('https://bing.com')            # cache miss, cache count = 3, 'https://stackoverflow.com' evicted
$PageTitleCache.Get('https://github.com')          # cache hit
$PageTitleCache.Get('https://google.com')          # cache hit
```

### Least Frequently Used (LFU)

Simple LFU policy which evicts the least recently cached entry of those least frequently used
```powershell
# Create a cache for URL page titles
$PageTitleCache = New-PSCache { param($url) (Invoke-WebRequest $url).title } -EvictionPolicy LFU -Capacity 3

# Grab a few url page titles
$PageTitleCache.Get('https://google.com')          # cache miss, cache count = 1
$PageTitleCache.Get('https://github.com')          # cache miss, cache count = 2
$PageTitleCache.Get('https://google.com')          # cache hit
$PageTitleCache.Get('https://stackoverflow.com')   # cache miss, cache count = 3
$PageTitleCache.Get('https://bing.com')            # cache miss, cache count = 3, 'https://stackoverflow.com' evicted
$PageTitleCache.Get('https://github.com')          # cache miss, cache count = 3, 'https://bing.com' evicted
$PageTitleCache.Get('https://google.com')          # cache hit
```

## Roadmap

PSCache is currently very basic. Future plans include both time- and counter-based eviction policies (globally and per-key), as well as explicit cache size settings.
