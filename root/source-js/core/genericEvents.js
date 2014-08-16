$(window).bind('beforeunload', function ()
{
    var messages = [];
    $.publish('/lizztcms/beforeunload',[ messages ]);
    if(messages.length)
    {
        return messages.join("\n");
    }
});
