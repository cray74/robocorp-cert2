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
# -


*** Variables ***
${csv_url}=     https://robotsparebinindustries.com/orders.csv

*** Keywords ***
Get orders
    Download     ${csv_url}     overwrite=True
    ${orders}=      Read table from CSV     orders.csv
    [Return]    ${orders}

*** Keywords ***
Open Website
    Open Available Browser  https://robotsparebinindustries.com/#/robot-order

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

# +
*** Keywords ***
Submit the order
    ${submit}=   Does Page Contain Element  id:order
        
    IF      ${submit}
        Click Button    id:order
        Submit the order
    END
    
    
# -

*** Keywords ***
Create pdf of receipt
    [Arguments]     ${order}
    ${filename}=    Catenate    SEPARATOR=  receipt-    ${order}[Order number]
    ${receipt_html}=    Get Element Attribute    id:receipt     outerHTML
    Html To Pdf    ${receipt_html}     ${CURDIR}${/}output${/}${filename}.pdf
    Screenshot      id:robot-preview-image    ${CURDIR}${/}output${/}${filename}.png
    ${robot_pic}=   Create List     ${CURDIR}${/}output${/}${filename}.png 
    Add Files To Pdf    ${robot_pic}   ${CURDIR}${/}output${/}${filename}.pdf    append=True
    Remove File     ${CURDIR}${/}output${/}${filename}.png 


*** Keywords ***
Zip receipts
        Archive Folder With Zip    ${CURDIR}${/}output${/}    ${CURDIR}${/}receipts.zip

*** Keywords ***
Cleanup
    Close Browser
    Empty Directory    ${CURDIR}${/}output${/}

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    # Ask for csv input file
    ${orders}=  Get orders
    Open Website
    FOR  ${order}  IN  @{orders}
        Fill in the form    ${order}
        Preview the robot
        Submit the order
        Create pdf of receipt   ${order}
        Order another robot
    END
    Zip receipts
    [Teardown]  Cleanup
