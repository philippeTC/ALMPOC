using ALMPOC.CRM.Plugins.Logic;
using Microsoft.Xrm.Sdk;
using Microsoft.Xrm.Sdk.Query;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ALMPOC.CRM.Plugins.Plugins.Account
{
    public class SetFieldValue : IPlugin
    {
        public void Execute(IServiceProvider serviceProvider)
        {
            try
            {
                AccountManager accManager = new AccountManager(serviceProvider, true);
                accManager.TraceService.Trace("Begin SetFieldValue plugin");
                accManager.TraceInputParameters();

                #region Verify execution context

                accManager.ValidateExecutionContext(this.GetType(), false);

                #endregion Verify execution context

                var context = accManager.PluginExecutionContext;
                var entity = (Entity)context.InputParameters["Target"];
                accManager.TraceInputEntityAttributes(entity);

                // set value
                entity.Attributes.Add("tickersymbol", "INFX");

                accManager.TraceService.Trace("End SetFieldValue plugin");
            }
            catch (Exception Ex)
            {
                throw new InvalidPluginExecutionException("Error occured in the SetFieldValue Plugin:" + Ex.Message);
            }
        }
    }
}
