/*
 * Handle cases where for some reason we have injected duplicate script loading
 */
if(window.LizztCMS && window.LizztCMS.version)
{
    if(window.lzError)
    {
        var message;
        if(! window.i18n)
        {
            window.i18n = {
                get: function(m)
                {
                    return m;
                }};
        }
        message = i18n.get('LizztCMS has loaded several instances on top of each other. This is dangerous, and can result in data corruption. Please save your work and then reload.');
        try {
            destroyPI();
            $('.progressWrapper').each(function()
            {
                $(this).parent().remove();
            });
            $('.ui-widget-overlay').remove();
            $('<div id="progressWrapper" class="progressWrapper" />').appendTo('.wrappers');
        } catch (e) {}
        lzError('Multiple JS instances loaded',message);
    }
    try
    {
        $('script').remove();
    } catch(e) { }
    throw('FATAL: Multiple JS instances loaded');
}

(function($)
{
    window.LizztCMS = window._L = {
        namespace: function(namespace)
        {
            if(this[namespace])
            {
                return this[namespace];
            }
            else
            {
                return this.addNamespace(namespace,{});
            }
        },

        addNamespace: function(namespace,methods)
        {
            if (!this[namespace])
            {
                this[namespace] = {
                    define: this.define,
                    addNamespace: this.addNamespace,
                    extendNamespace: this.extendNamespace,
                    namespace: this.namespace
                };
            }
            return this[namespace].define(methods);
        },

        extendNamespace: function(namespace,methods)
        {
            return this.addNamespace(namespace,methods);
        },

        define: function(methods)
        {
            $.extend(this,methods);
            return this;
        }
    };

    LizztCMS.define({
        version: function()
        {
            return $('#lizztcms_version').val();
        }
    });
})(jQuery);
