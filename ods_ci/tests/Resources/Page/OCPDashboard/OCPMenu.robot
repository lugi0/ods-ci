*** Settings ***
Resource  ../../Common.robot
Library  JupyterLibrary
Library  String
Library  OpenShiftLibrary

*** Variables ***
${APP_LAUNCHER_ELEMENT}                 xpath://button[@aria-label="Application launcher"]
${PERSPECTIVE_SWITCHER_BUTTON_ELEMENT}  xpath=//*[@data-test-id="perspective-switcher-toggle"]
${PERSPECTIVE_SWITCHER_TEXT_ELEMENT}  xpath=//*[@data-test-id="perspective-switcher-toggle"]/span/h2
${PERSPECTIVE_ADMINISTRATOR_BUTTON}  xpath=//*[@data-test-id="perspective-switcher-menu-option"][starts-with(., "Administrator")]
${PERSPECTIVE_DEVELOPER_BUTTON}      xpath=//*[@data-test-id="perspective-switcher-menu-option"][starts-with(., "Developer")]
${LOADING_INDICATOR_ELEMENT}         xpath=//*[@data-test="loading-indicator"]

*** Keywords ***
Wait Until OpenShift Console Is Loaded
  ${expected_text_list}=    Create List    Administrator    Developer
  Wait Until Page Contains A String In List    ${expected_text_list}
  Wait Until Element Is Enabled    ${APP_LAUNCHER_ELEMENT}  timeout=60

Switch To Administrator Perspective
  Wait Until Page Contains Element     ${PERSPECTIVE_SWITCHER_TEXT_ELEMENT}  timeout=30
  Maybe Skip Tour
  ${current_perspective}=   Get Text  ${PERSPECTIVE_SWITCHER_TEXT_ELEMENT}
  IF  '${current_perspective}' != 'Administrator'
      Click Button    ${PERSPECTIVE_SWITCHER_BUTTON_ELEMENT}
      Wait Until Page Does Not Contain Element   ${LOADING_INDICATOR_ELEMENT}  timeout=30
      Wait Until Element Is Visible    ${PERSPECTIVE_ADMINISTRATOR_BUTTON}  timeout=30
      Sleep  1
      Click Element   ${PERSPECTIVE_ADMINISTRATOR_BUTTON}
      Wait Until Page Does Not Contain Element   ${LOADING_INDICATOR_ELEMENT}  timeout=30
      Wait Until Page Contains Element     ${PERSPECTIVE_SWITCHER_TEXT_ELEMENT}  timeout=30
  END

Switch To Developer Perspective
  Wait Until Page Contains Element     ${PERSPECTIVE_SWITCHER_TEXT_ELEMENT}   timeout=30
  Maybe Skip Tour
  ${current_perspective}=   Get Text  ${PERSPECTIVE_SWITCHER_TEXT_ELEMENT}
  IF  '${current_perspective}' != 'Developer'
      Click Button    ${PERSPECTIVE_SWITCHER_BUTTON_ELEMENT}
      Wait Until Page Does Not Contain Element   ${LOADING_INDICATOR_ELEMENT}  timeout=30
      Wait Until Element Is Visible    ${PERSPECTIVE_DEVELOPER_BUTTON}  timeout=30
      Sleep  1
      Click Element   ${PERSPECTIVE_DEVELOPER_BUTTON}
      Wait Until Page Does Not Contain Element   ${LOADING_INDICATOR_ELEMENT}  timeout=30
      Wait Until Page Contains Element     ${PERSPECTIVE_SWITCHER_TEXT_ELEMENT}  timeout=30
  END

Maybe Skip Tour
    [Documentation]    If we are in the openshift web console, maybe skip the first time
    ...    tour popup given to users, otherwise RETURN.
    ${should_cont} =    Does Current Sub Domain Start With    https://console-openshift-console
    IF  ${should_cont}==False
        RETURN
    END
    ${tour_modal} =  Run Keyword And Return Status  Wait Until Page Contains Element  xpath=//div[@id='guided-tour-modal']  timeout=5s
    IF  ${tour_modal}  Click Element  xpath=//div[@id='guided-tour-modal']/button

Get OpenShift Version
    [Documentation]   Get the installed openshitf version on the cluster.
    ${data}=   Oc Get    kind=ClusterVersion
    ${version}=   Split String From Right    ${data[0]['status']['desired']['version']}      .    1
    RETURN     ${version[0]}
