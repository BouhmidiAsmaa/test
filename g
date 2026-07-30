using Microsoft.Xrm.Sdk;
using Microsoft.Xrm.Sdk.Query;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;

namespace Fondaction.SGRC.Custom.Activities
{
    public class BlockContactEpargantUpdateFromMarketing : IPlugin
    {

        private static readonly string[] ServiceAccountRoles =
        {
            "Fondaction - Service Account BOF",
            "Fondaction - Service Account Dataverse"
        };

        private const string EnvironmentVariableSchemaName =
            "fond_contactactionnaire_champs_autorises";

        public void Execute(IServiceProvider serviceProvider)
        {
            var tracingService =
                (ITracingService)serviceProvider.GetService(typeof(ITracingService));

            var context =
                (IPluginExecutionContext)serviceProvider.GetService(typeof(IPluginExecutionContext));

            var serviceFactory =
                (IOrganizationServiceFactory)serviceProvider.GetService(typeof(IOrganizationServiceFactory));

            var service =
                serviceFactory.CreateOrganizationService(null);

            try
            {
                tracingService.Trace("BlockContactActionnaireUpdate - START");

                #region Validation contexte

                if (!string.Equals(context.MessageName, "Update", StringComparison.OrdinalIgnoreCase))
                {
                    tracingService.Trace("Message différent de Update.");
                    return;
                }

                if (!context.InputParameters.Contains("Target"))
                {
                    tracingService.Trace("Target absent.");
                    return;
                }

                if (!(context.InputParameters["Target"] is Entity target))
                {
                    tracingService.Trace("Target invalide.");
                    return;
                }

                if (target.Attributes.Count == 0)
                {
                    tracingService.Trace("Aucun attribut modifié.");
                    return;
                }

                #endregion

                #region Identification Actionnaire

                Entity preImage = null;

                if (context.PreEntityImages.Contains("PreImage"))
                {
                    preImage = context.PreEntityImages["PreImage"];
                }

                if (preImage == null)
                {
                    throw new InvalidPluginExecutionException(
                        "La PreImage est requise pour le plugin BlockContactActionnaireUpdate.");
                }

                var epargnant = preImage.GetAttributeValue<EntityReference>("fond_epargnantid");

                tracingService.Trace($"epargnant : {epargnant}");

                // Contact non actionnaire
                if (epargnant == null)
                {
                    tracingService.Trace("Contact non actionnaire. Fin du traitement.");
                    return;
                }

                #endregion

                #region Vérification comptes de service

                if (UserHasServiceRole(service, context.InitiatingUserId, tracingService))
                {
                    tracingService.Trace("Compte de service détecté. Modification autorisée.");
                    return;
                }

                #endregion

                #region Chargement whitelist

                var allowedFields =
                    GetAllowedFields(service, tracingService);

                tracingService.Trace(
                    $"Nombre de champs autorisés : {allowedFields.Count}");

                #endregion

                #region Analyse des champs modifiés

                var modifiedFields = target.Attributes.Keys
                    .Select(x => x.ToLower())
                    .ToList();

                tracingService.Trace(
                    "Champs modifiés : " +
                    string.Join(", ", modifiedFields));

                var unauthorizedFields = modifiedFields
                    .Where(field => !allowedFields.Contains(field))
                    .ToList();

                if (unauthorizedFields.Any())
                {
                    tracingService.Trace(
                        "Champs refusés : " +
                        string.Join(", ", unauthorizedFields));

                    throw new InvalidPluginExecutionException(
                        "Ce contact est un actionnaire et seules certaines informations peuvent être modifiées.");
                }

                tracingService.Trace("Tous les champs modifiés sont autorisés.");

                #endregion
            }
            catch (InvalidPluginExecutionException)
            {
                throw;
            }
            catch (Exception ex)
            {
                tracingService.Trace("Exception : " + ex);

                throw new InvalidPluginExecutionException(
                    "Une erreur est survenue lors de la validation du contact actionnaire.");
            }
        }

        private bool UserHasServiceRole(
            IOrganizationService service,
            Guid userId,
            ITracingService tracingService)
        {
            var query = new QueryExpression("role")
            {
                ColumnSet = new ColumnSet("name")
            };

            var userRoleLink = new LinkEntity(
                "role",
                "systemuserroles",
                "roleid",
                "roleid",
                JoinOperator.Inner);

            userRoleLink.LinkCriteria.AddCondition(
                "systemuserid",
                ConditionOperator.Equal,
                userId);

            query.LinkEntities.Add(userRoleLink);

            var roles = service.RetrieveMultiple(query);

            foreach (var role in roles.Entities)
            {
                var roleName = role.GetAttributeValue<string>("name");

                tracingService.Trace($"Role trouvé : {roleName}");

                if (ServiceAccountRoles.Any(r =>
                    string.Equals(r, roleName, StringComparison.OrdinalIgnoreCase)))
                {
                    return true;
                }
            }

            return false;
        }

        private HashSet<string> GetAllowedFields(
            IOrganizationService service,
            ITracingService tracingService)
        {
            var result = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            var query = new QueryExpression("environmentvariabledefinition")
            {
                ColumnSet = new ColumnSet("schemaname")
            };

            query.Criteria.AddCondition(
                "schemaname",
                ConditionOperator.Equal,
                EnvironmentVariableSchemaName);

            var valueLink = new LinkEntity(
                "environmentvariabledefinition",
                "environmentvariablevalue",
                "environmentvariabledefinitionid",
                "environmentvariabledefinitionid",
                JoinOperator.LeftOuter);

            valueLink.EntityAlias = "envValue";
            valueLink.Columns = new ColumnSet("value");

            query.LinkEntities.Add(valueLink);

            var variables = service.RetrieveMultiple(query);

            var variable = variables.Entities.FirstOrDefault();

            if (variable == null)
            {
                tracingService.Trace(
                    $"Variable d'environnement introuvable : {EnvironmentVariableSchemaName}");

                return result;
            }

            string value = null;

            if (variable.Contains("envValue.value"))
            {
                value = ((AliasedValue)variable["envValue.value"])
                    ?.Value
                    ?.ToString();
            }

            tracingService.Trace($"Valeur whitelist : {value}");

            if (!string.IsNullOrWhiteSpace(value))
            {
                foreach (var field in value.Split(','))
                {
                    var fieldName = field.Trim().ToLower();

                    if (!string.IsNullOrWhiteSpace(fieldName))
                    {
                        result.Add(fieldName);
                    }
                }
            }

            // Champs techniques à ignorer
            result.Add("modifiedon");
            result.Add("modifiedby");
            result.Add("modifiedonbehalfby");

            return result;
        }

    }
}
