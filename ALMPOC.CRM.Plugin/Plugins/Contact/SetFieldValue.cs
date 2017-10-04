using ALMPOC.CRM.Plugins.Logic;
using Microsoft.Xrm.Sdk;
using Microsoft.Xrm.Sdk.Query;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ALMPOC.CRM.Plugins.Plugins.Contact
{
    public class SetFieldValue : IPlugin
    {
        public void Execute(IServiceProvider serviceProvider)
        {
            try
            {
                ContactManager contactManager = new ContactManager(serviceProvider, true);
                contactManager.TraceService.Trace("Begin SetFieldValue plugin");
                contactManager.TraceInputParameters();

                #region Verify execution context

                contactManager.ValidateExecutionContext(this.GetType(), false);

                #endregion Verify execution context

                var context = contactManager.PluginExecutionContext;
                var entity = (Entity)context.InputParameters["Target"];
                contactManager.TraceInputEntityAttributes(entity);

                // set value
                //entity.Attributes.Add("tickersymbol", "INFX");

                contactManager.TraceService.Trace("End SetFieldValue plugin");
            }
            catch (Exception Ex)
            {
                throw new InvalidPluginExecutionException("Error occured in the SetFieldValue Plugin:" + Ex.Message);
            }
        }
    }
}
