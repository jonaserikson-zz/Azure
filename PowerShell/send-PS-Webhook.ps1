$webhook = 'https://outlook.office.com/webhook/d20d4895-e2ce-4a8f-8b90-dc1ce44e54ba@e11cbe9c-f680-44b9-9d42-d705f740b888/IncomingWebhook/7c188d3b246445308e34418c56008b21/1d8ad121-3215-48b3-b545-64df4e354fea'
$Body = @{
        'text'= 'Testing webhook'
}

$params = @{
    Headers = @{'accept'='application/json'}
    Body = $Body | convertto-json
    Method = 'Post'
    URI = $webhook
}

Invoke-RestMethod @params
