@echo off
SET CrmDeploymentType="3"

if %CrmDeploymentType%=="1" goto :ActiveDirectory
if %CrmDeploymentType%=="2" goto :Federation
if %CrmDeploymentType%=="3" goto :Online

:ActiveDirectory
ECHO Generate Proxy File for https://xxxxx.api.crm4.dynamics.com/XRMServices/2011/Organization.svc
C:\Infront\CRM2016\bin\CrmSvcUtil.exe /language:CS /url:https://xxxxx.api.crm4.dynamics.com/XRMServices/2011/Organization.svc /out:"XrmSdk.cs" /namespace:ALMPOC.CRM.Plugins.CrmServices.XrmSdk /serviceContextName:ServiceContext /codewriterfilter:Infront.SvcUtilFilter.CodeWriterFilter,Infront.SvcUtilFilter /codecustomization:Infront.SvcUtilFilter.CustomizeCodeDomService,Infront.SvcUtilFilter


goto :End

:Federation
:Online
ECHO Generate Proxy File for https://xxxx.api.crm4.dynamics.com/XRMServices/2011/Organization.svc
C:\Infront\CRM2016\bin\CrmSvcUtil.exe /language:CS /url:https://xxxx.api.crm4.dynamics.com/XRMServices/2011/Organization.svc /out:"XrmSdk.cs" /namespace:ALMPOC.CRM.Plugins.CrmServices.XrmSdk /serviceContextName:ServiceContext /codewriterfilter:Infront.SvcUtilFilter.CodeWriterFilter,Infront.SvcUtilFilter /codecustomization:Infront.SvcUtilFilter.CustomizeCodeDomService,Infront.SvcUtilFilter /username:"xxxx@nikogroup.onmicrosoft.com" /password:"xxxx"

:End
pause