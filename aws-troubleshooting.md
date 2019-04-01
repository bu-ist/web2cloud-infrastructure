
## Athena

### Sources

https://aws.amazon.com/premiumsupport/knowledge-center/analyze-logs-athena/

https://aws.amazon.com/blogs/big-data/top-10-performance-tuning-tips-for-amazon-athena/

SELECT *
FROM cloudfront_logs_prod
WHERE date = date '2019-03-07' and parse_datetime(time, 'HH:mm:ss') between parse_datetime('02:30:00', 'HH:mm:ss') and parse_datetime('03:30:00', 'HH:mm:ss') and status = 502
ORDER BY  time
limit 10

## CloudWatch Log Insights

### Sources

https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_AnalyzeLogData_VisualizationQuery.html
https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_Insights-Visualizing-TimeSeries.html
https://aws.amazon.com/blogs/aws/new-amazon-cloudwatch-logs-insights-fast-interactive-log-analytics/
https://searchaws.techtarget.com/tip/CloudWatch-Logs-Insights-wont-replace-third-party-tools-yet

### Example queries

```
fields @timestamp, @message
| parse 'access_log: * - - [*] "* * *" * * * * *' as @ip, @date, @method, @uri, @protocol, @ret, @bytes_returned, @request_time, @upstream_time, @rest
| filter @uri like /^\/link\/bin/
| filter @ret > 500
| sort @timestamp desc
| stats count() by @uri
```

```
fields @timestamp, @message
| parse 'access_log: * - - [*] "* * *" * * * * *' as @ip, @date, @method, @uri, @protocol, @ret, @bytes_returned, @request_time, @upstream_time, @rest
| filter @uri like /^\/link\/bin/
| sort @timestamp desc
| stats count(), avg(@request_time), max(@request_time) by @ret
```

```
fields @timestamp, @message
| parse 'access_log: * - - [*] "* * *" * * * * *' as @ip, @date, @method, @uri, @protocol, @ret, @bytes_returned, @request_time, @upstream_time, @rest
| filter @uri like /^\/link\/bin/
| filter @request_time > 15.0
| sort @timestamp desc
| stats count() by bin(1m)
```

```
fields @timestamp, @message
| parse 'access_log: * - - [*] "* * *" * * * * *' as @ip, @date, @method, @uri, @protocol, @ret, @bytes_returned, @request_time, @upstream_time, @rest
| filter @uri like /^\/link\/bin/
| filter @ret > 500
| sort @timestamp desc
| stats avg(@request_time) by bin(1m)
```

```
fields @timestamp, @message
| parse 'access_log: * - - [*] "* * *" * * * * *' as @ip, @date, @method, @uri, @protocol, @ret, @bytes_returned, @request_time, @upstream_time, @rest
| filter @uri like /^\/link\/bin/
| filter @ret > 500
| sort @timestamp desc
| stats count() by @ret
```

fields @timestamp, @message
| parse 'access_log: * - - [*] "* * *" * * * * *' as @ip, @date, @method, @uri, @protocol, @ret, @bytes_returned, @request_time, @upstream_time, @rest
| filter @uri like /^\/link\/bin/
| sort @timestamp desc
| stats count() by @ret

```
fields @timestamp, @message
| filter @message like /upstream prematurely closed connection while reading response header from upstream/
| sort @timestamp desc
| stats count() by bin(1m)
```

```
fields @timestamp, @message
| parse 'access_log: * - - [*] "* * *" * * * * *' as @ip, @date, @method, @uri, @protocol, @ret, @bytes_returned, @request_time, @upstream_time, @rest
| filter not @uri like /^\/link\/bin/
| filter @ret > 500
| sort @timestamp desc
| stats avg(@request_time) by bin(1m)
```

## F5 configuration items

https://devcentral.f5.com/questions/tcp-request-queueing

https://support.f5.com/csp/article/K9849

https://support.f5.com/csp/article/K9812

The following talks about TCP connection setup for stuff
https://support.f5.com/csp/article/K8082

Overview of F5 idle session timeouts:
https://support.f5.com/csp/article/K7606

https://support.f5.com/kb/en-us/products/big-ip_ltm/manuals/product/ltm-implementations-13-0-0/24.html

https://devcentral.f5.com/questions/f5-connection-limit-and-queuing-unexpected-behavior
