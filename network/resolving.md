How to check if a URL can be reachable from a specific IP:
```
dig NAME-ID.REGION.elb.amazonaws.com
```

Then use the resolved IP to curl the URL:
```
curl --resolve HOST:PORT:IP https://url
```

User full for protecting the LB and origin servers from being accessed from the public internet.