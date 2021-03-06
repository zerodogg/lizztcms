/*
 * LizztCMS content management system
 * Copyright (C) Utrop A/S Portu media & Communications 2008-2011
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
/*
 * LizztCMS shared error handling code
 *
 * Copyright (C) Portu media & communications
 * All Rights Reserved
 */

function displayErrorBox (title,message)
{
    var $dialog = $('<div/>').appendTo('body');
    $dialog.html(message);
    $dialog.dialog({
        buttons: {
                'Close': function() {
                    $(this).dialog('close');
                }
            },
        title: title,
        modal: true,
        width: 680,
        close: function ()
        {
            try
            {
                $dialog.remove();
            } catch(e) {
                $dialog.empty();
            }
        }
    });
}

/*
 * Get the file and line number that caused the exception if
 * possible. Returns null if it isn't possible.
 */
function getExceptionLocation (backtrace)
{
    var bt = backtrace[0];
    if(! /https?:/.test(bt))
    {
        bt = backtrace[1];
    }
    if(! /https?:/.test(bt))
    {
        return;
    }
    return bt;
}

function getLzErrInfo (add)
{
    var userAgent = '(unknown)',
        URL = '(unknown)',
        user = '(unknown)',
        lzVer = '';
    // Get the current URL
    try {
        if(document.url)
            URL = document.url;
        else if(document.URL)
            URL = document.URL;
        else if(window.location)
            URL = window.location;
        URL = URL.replace(/&/,'&amp;');
    } catch(e) { lzelog(e); }
    // Get the user agent
    try { userAgent = navigator.userAgent; } catch(e) { }
    // Get the current LizztCMS version
    try { lzVer = $('#lizztcms_version').val(); } catch(e) { }
    // Get the current username+user id
    try { user = $('#currentUsername').val(); user = user +'/'+$('#currentUserId').val(); } catch(e) { }
    // Generate the actual message string
    var message = '<code class="errorInformation"';
    try
    {
        if(/git\//.test($('#lizztcms_version').val()))
        {
            message = message+' style="color:black"';
        }
    }
    catch(e) { }
    message = message +'>';
    message = message+add;
    message = message+'User&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: '+user+'<br />';
    message = message+'On page&nbsp;&nbsp;&nbsp;: '+URL+'<br />';
    message = message+'User agent: '+userAgent+'<br />';
    message = message+'LizztCMS&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: '+lzVer;
    try
    {
        message = message+'<br />At&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: '+(new Date).toString();
    } catch(e) { }
    message = message+'</code>';
    return message;
}

/*
 * Summary: LizztCMS javascript exception handler
 * Arguments:
 *  exception: exception object
 *  error: optional error message
 *
 * This will provide some additional information about the nature of the exception
 * and handle giving a generic error message if one isn't supplied.
 */
function lzException(exception,error)
{
    var exceptMsg = '(unknown/missing)';

    // Store exceptions
    if(exception && console && console.log)
    {
        lzStoredExceptions.push(exception);
    }

    var caller = '(unknown)';
    try
    {
        try { caller = exception.lzIntCaller; } catch(e) { caller = '(unknown)'; }
        if(caller === undefined || caller == '(unknown)')
        {
            caller = getCallerName(arguments);
            if(caller)
            {
                caller = caller.replace(/^\s*at\s*/,'');
            }
        }

    } catch(e) {}
    try { 
        url = document.url; 
        url = url.replace(/&/,'&amp;');
    } catch(e) { }
    
    var message = '';
    if(error)
    {
        message = error;
    }
    else
    {
        var internal = false;
        try { if(exception.internalLizztCMSError) { internal = true }; }  catch(e) { }
        if(internal)
        {
            message = "An internal error occurred. This means that some part of your LizztCMS instance just had a serious problem. If you were saving some data, that data may not have been saved. Please try again in a few moments. If the problem persists, please supply the LizztCMS developers with the information at the bottom of this message.";
        }
        else
        {
            message = "An exception occurred. This means that some part of your LizztCMS instance just crashed. Please try again in a few moments. If the problem persists, please supply the LizztCMS developers with the information at the bottom of this message.";
        }
    }

    message = '<span onselectstart="return false;" unselectable="on">'+message+'</span>';
    message = message+'<br /><br /><small>';

    if(error)
    {
        message = message+'<i>Error information:</i><br />';
    }

    try { 
        if (exception && exception.message)
        {
            exceptMsg = exception.message;
        }
        else
        {
            if(exception.lzIntCaller)
            {
                exceptMsg = '(exception data missing/null (lzError mode))';
            }
            else if(exception)
            {
                var type = 'unknown';
                try { type = typeof(exception); } catch(e) { }
                if(type == 'object')
                {
                    exceptMsg = '(exception message missing/null (got object))';
                }
                else if(type == 'string')
                {
                    exceptMsg = '(got string exception): '+exception;
                }
                else
                {
                    exceptMsg = '(exception message missing/null (got object of type "'+type+'" - stringifies as:'+exception+'))';
                }
            }
            else
            {
                exceptMsg = '(exception data missing/null)';
            }
        }
        try { if(exceptMsg === undefined || exceptMsg == null || exceptMsg == 'undefined' || exceptMsg == '') { exceptMsg = '(unknown/missing)'; } } catch(e) { }
    } catch (e) { }

    // Don't do anything if it's an lzError exception
    if (/^lzError/.test(exceptMsg))
    {
        return;
    }
    var backtrace = printStackTrace({e: exception});
    var exceptionLocation = getExceptionLocation(backtrace);
        extraInfo = '';

    extraInfo = extraInfo+'Exception : '+exceptMsg+"<br />";
    if(exceptionLocation != null)
    {
        extraInfo = extraInfo+'At&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: '+exceptionLocation+'<br />';
    }
    extraInfo = extraInfo+'Caught by : '+caller+"<br />";
    if($.browser.ie && /JSON/.match(caller))
    {
        if(lizztcms_curr_JSON_URL)
        {
            extraInfo = extraInfo+'JSON URL: '+lizztcms_curr_JSON_URL;
        }
    }
    message = message+getLzErrInfo(extraInfo);

    // Try to clean up so that the page can be used in case something
    // has made it impossible to use
    try {
        for(var i = 0; i <= dialogNo; i++)
        {
            var dialog = $('#dialog_no_'+i);
            if (dialog)
            {
                if(dialog.dialog('option','isOpen'))
                {
                    dialog.dialog('option','modal',false);
                }
                else
                {
                    dialog.css({
                        'visibility':'hidden',
                        'display':'none'
                    });
                    dialog.empty();
                }
            }
        }
    } catch(e) { }

    // Ensure that any running progress indicator doesn't overwrite our dialog window
    try { PI_noSoonMessage = PI_currProgress; } catch(e) { }

    message = message +'</small>';
    lzelog(exception,backtrace);

    // Display our message
    try
    {
        displayErrorBox('Fatal error',message);
        try
        {
            $('.errorInformation').click(function()
            {
                var $ei = $('.errorInformation');
                var message = $ei.html().replace(/<br[^>]*>/g,"\n").replace(/&nbsp;/g,' ');
                var $ta = $('<textarea/>').css({
                    height:$ei.height(),
                    width:$ei.width(),
                    'font-size':$ei.css('font-size')
                }).text(message);
                $ei.hide();
                $ta.appendTo($ei.parent());
                $ta[0].focus();
                $ta[0].select();
                $ta.focusout(function()
                {
                    $ta.remove();
                    $ei.show();
                });
            });
        } catch(ign) { }
    }
    catch(e)
    {
        try
        {
            message = message.replace(/<br \/>/g,"\n");
            message = message.replace(/&nbsp;/g,' ');
            message = message.replace(/<[^>]+>/g,'');
        } catch(e) {}
        alert(message);
    }
}

/*
 * Summary: LizztCMS javascript exception logger
 * Arguments: exception: exception object
 */
function lzelog (exception,backtrace)
{
    try
    {
        var funcname = null;
        if(backtrace == null)
        {
            backtrace = printStackTrace({ e: exception });
        }
        try 
        {
            funcname = getCallerName(exception.stack);
        } catch(e) { }
        var message = exception.message;
        var output = '"'+message+'"';
        if(funcname != null)
        {
            output = output + ' in '+funcname;
        }
        if(progIndicatorDisplayed && arguments.length != 2)
        {
            PI_exceptions.push(output);
        }
        lzlog('Exception: '+output);
        if (backtrace)
        {
            lzlog("Stack trace of above exception:\n"+backtrace.join("\n"));
        }
        LizztCMS.errorLog.send(output);
    } catch(e) { }
}

function lzErrLog (error)
{
    try
    {
        if(error == null || error == '')
        {
            return;
        }
        lzlog('Error: '+error);
        LizztCMS.errorLog.send(error);
    } catch(e) { }
}

/*
 * Summary: Provide an exception dialog for non-exception errors
 *
 * This function lets you create the lzException() dialog, without
 * having to throw and catch an error.
 *
 * Arguments:
 *  error (required) = The error that will show up as the exception message
 *  userError = The user-facing error message, this is the same as the error
 *      parameter to lzException. It's optional. An autogenerated one will
 *      be shown if this is not supplied.
 *  fatal = bool, if true then lzError will throw() an exception matching
 *      /^lzError/ (this exception is ignored by lzException().
 */
function lzError (error,userError,fatal)
{
    var exception = {};
    exception.message = error;
    exception.internalLizztCMSError = true;
    if(arguments && arguments.length && arguments[3])
    {
        exception.lzIntCaller = arguments[3];
    }
    lzException(exception,userError);
    if(fatal === true)
    {
        throw({'message':'lzErrorException '+error});
    }
}

try
{
    window.onerror = function(msg, file, line)
    {
        if(file && line)
            msg = msg +' at '+file+':'+line;
        lzlog(arguments);
        lzlog(this);
        if (! (msg instanceof String))
        {
            lzlog(msg);
            return;
        }
        lzError(msg,null,false,'(onerror)');
        return false;
    };
} catch(e) {}

LizztCMS.addNamespace('error',
{
    exception: lzelog,
    log: lzErrLog,
    message: lzError,
    exception: lzException,
    getInfo: getLzErrInfo
});
LizztCMS.extendNamespace('message',
{
    error: displayErrorBox
});
