# PSCache
Generic PowerShell cache implementation

----

### What is PSCache?

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

### Roadmap

PSCache is currently very basic. Future plans include both time- and counter-based eviction policies (globally and per-key), as well as explicit cache size settings.
