param actionGroupName string
param actionGroupShortName string
param actionGroupEmail string
param location string

resource devTeamSendEmailActionGroup 'Microsoft.Insights/actionGroups@2022-06-01' = {
  name: actionGroupName
  location: location
  properties: {
    enabled: true
    groupShortName: actionGroupShortName
    emailReceivers: [
      {
        name: actionGroupName
        emailAddress: actionGroupEmail
        useCommonAlertSchema: true
      }
    ]
  }
}

output actoinGroupId string = devTeamSendEmailActionGroup.id
