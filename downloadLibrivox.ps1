#Download file
function Invoke-DownloadLibrivoxFile($author, $bookname, $bookid, $filename){
    New-Item "/docker/booksonic/Librivox/$author/$bookname\" -ItemType Directory -Force
    if(-not(Test-Path "/docker/booksonic/Librivox/$author/$bookname/$filename")){
        Invoke-Webrequest -Uri "https://archive.org/download/$bookid/$filename" -OutFile "/docker/booksonic/Librivox/$author/$bookname/$filename"
    }
}


#Get 100 most downloaded books
(
    Invoke-Webrequest "https://archive.org/advancedsearch.php?q=-title:(Thumbs) AND -title:(LibrivoxCDCoverArt) AND -title:(Collection) AND collection:(librivoxaudio)&fl=runtime,avg_rating,num_reviews,title,description,identifier,creator,date,downloads,subject,item_size&sort[]=downloads%20desc&rows=150&page=1&output=json"|
    select -ExpandProperty content|
    ConvertFrom-Json|
    select -ExpandProperty response|
    select -ExpandProperty docs
)|Select -first 150 |Foreach-Object{
    
    $bookinfo = $_
    New-Item "/docker/booksonic/Librivox/$($bookinfo.creator)/$($bookinfo.title)/" -ItemType Directory -Force
    if(-not(Test-Path "/docker/booksonic/Librivox/$($bookinfo.creator)/$($bookinfo.title)/desc.txt")){
        $bookinfo.description| Out-File "/docker/booksonic/Librivox/$($bookinfo.creator)/$($bookinfo.title)/desc.txt" -Encoding utf8
    }
    #Get book files
    (
        Invoke-Webrequest "https://archive.org/metadata/$($bookinfo.identifier)/files"|
        select -ExpandProperty content|
        ConvertFrom-Json|
        select -ExpandProperty result|
        where{ $_.source -eq "original" -and $_.name -notlike "*.zip" -and $_.name -notlike "*.m4b" }
    )|ForEach-Object{

        Invoke-DownloadLibrivoxFile $($bookinfo.creator) $($bookinfo.title) $($bookinfo.identifier) $_.name

    }

}
