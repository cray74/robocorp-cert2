# +
*** Settings ***
Documentation   Bot to complete certification level 2
...             order robots from a csv input file, take a screenshot
...             of each bot and order, and zip-up all receipts

Library         RPA.Browser.Selenium
Library         RPA.HTTP
Library         RPA.PDF
Library         RPA.Tables
Library         RPA.FileSystem
Library         RPA.Archive
Library         RPA.Dialogs
Library         RPA.Robocorp.Vault
# -


*** Variables ***
${csv_url}=     https://robotsparebinindustries.com/orders.csv
${path_output}=        ${CURDIR}${/}output${/}
# ${path_receipts}=      ${CURDIR}${/}output${/}receipts${/}
${path_receipts}=      ${path_output}receipts${/}

*** Keywords ***
Dummy
    Log     ${path_receipts}

*** Keywords ***
Get orders
    Download     ${csv_url}     overwrite=True
    ${orders}=      Read table from CSV     orders.csv
    [Return]    ${orders}

*** Keywords ***
Get ZIP-file-name
    Add heading    How should the zip-file be named (w/o .zip)?
    Add text input    zipfilename
    ...     label=zipfilename
    ...     placeholder=receipts
    ${result}=     Run dialog
    [Return]    ${result}[zipfilename]

*** Keywords ***
Open Website
    #Open Available Browser  https://robotsparebinindustries.com/#/robot-order
    ${secret}=     Get Secret    robotsparebin
    Open Available Browser  ${secret}[url]

*** Keywords ***
Fill in the form
    [Arguments]     ${order}
    Click Button    OK
    Select From List By Index    id:head    ${order}[Head]
    Select Radio Button      body   ${order}[Body]
    Input Text      xpath://label[contains(.,'3. Legs:')]/../input  ${order}[Legs]
    Input Text      id:address   ${order}[Address]

*** Keywords ***
Preview the robot
    Click Button    Preview

*** Keywords ***
Order another robot
    Click Button    id:order-another

*** Keywords ***
Submit the order
    ${submit}=   Does Page Contain Element  id:order
        
    IF      ${submit}
        Click Button    id:order
        Submit the order
    END

*** Keywords ***
Create pdf of receipt
    [Arguments]     ${order}
    ${filename}=    Catenate    SEPARATOR=  ${path_receipts}   receipt-    ${order}[Order number]
    ${receipt_html}=    Get Element Attribute    id:receipt     outerHTML
    Html To Pdf    ${receipt_html}     ${filename}.pdf
    Screenshot      id:robot-preview-image    ${filename}.png
    ${robot_pic}=   Create List     ${filename}.png 
    Add Files To Pdf    ${robot_pic}   ${filename}.pdf    append=True
    Remove File     ${filename}.png 


*** Keywords ***
Zip receipts
        [Arguments]     ${zipfilename}
        Archive Folder With Zip    ${path_receipts}    ${path_output}${zipfilename}.zip   include=*.pdf

*** Keywords ***
Cleanup
    Close Browser
    Empty Directory    ${path_receipts}

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${zipfilename}=     Get ZIP-file-name
    ${orders}=  Get orders
    Open Website
    FOR  ${order}  IN  @{orders}
        Fill in the form    ${order}
        Preview the robot
        Submit the order
        Create pdf of receipt   ${order}
        Order another robot
    END
    Zip receipts    ${zipfilename}
    [Teardown]  Cleanup
