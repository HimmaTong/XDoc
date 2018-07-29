#
# ����һ����Ŀ�����������ݵĲ˵�
#

param($Directory)

class Toc {
    Toc($content) {
        $this.TContent = $content
    }

    [string[]] $TContent
    [Collections.Generic.List[TocItem]] $Items = [Collections.Generic.List[TocItem]]::new(4)

    # ת���ɶ���
    [TocItem[]] ToToc($i, [TocItem[]] $tocItems) {
        $content = $this.TContent

        for (; $i -lt $content.Length; $i++) {
            [string] $item = $content[$i]

            if (!$item.TrimStart(" ").StartsWith("- name")) {
                continue
            }

            [TocItem] $tocItem = [TocItem]::new()

            if ($tocItems.Count -eq 0 ) {
                $tocItems = @($tocItem)
            }
            else {
                $tocItems = $tocItems + $tocItem
            }


            #$tocItems.Add($tocItem)

            $tocItem.Name = $item

            $item = $content[$i + 1]

            if ($item.TrimStart(" ").StartsWith("href")) {
                $tocItem.Href = $item
                $i++
                $item = $content[$i + 1]
            }

            if ($item.TrimStart(" ").StartsWith("items")) {
                $tocItem.Items = [Collections.Generic.List[TocItem]]::new()
                $i++
                $this.ToToc($i, $tocItem.Items)
            }
        }

        return $tocItems
    }

    [string] ToString () {
        return "666"
    }
}

class TocItem {
    [string] $Name
    [string] $Href
    [Collections.Generic.List[TocItem]] $Items
}



# Ŀ¼�ļ�
$tocPath = $Directory + "/toc.md"

# Ŀ¼����
[Collections.Generic.List[string]] $tocContent

#��Ŀ¼����
[String[]] $newTocContent

# ��ȡĿ¼����
If (Test-Path $tocPath) {
    $tocContent = Get-Content -Path $tocPath -Encoding UTF8
}

#$toc = [Toc]::new($tocContent)
#$toc.ToToc(0, $toc.Items)
#$toc.ToString()

# ����Ŀ¼
function buildToc($dirPath) {

    # �����жϵ�ǰĿ¼�Ƿ���md�ļ������ļ��У�û���򷵻�

    #If(Test-Path ($dirPath + "/index.md")){
    #	$tocContent = Get-Content -Encoding UTF8
    #}

	[String[]] $newTocContent

    # ��ȡ�ļ���Ϣ��-Recurse��ʾ������Ŀ¼
    $fileInfo = Get-ChildItem  $dirPath -Recurse -Include *.md -Exclude index.md,toc*.md

    # ��¼��һ�θ����ļ��е�����Ŀ $Directory ��·��
    $pPath = ""

    $fileInfo | foreach {
        # ���ӵ�ַ
        $linkName = $_.FullName.Replace($Directory, "").TrimStart("\\")

        # ��ȣ�������������ɲ㼶��ϵ
        $depth = $linkName.Split('\\').Length - 1

        # �ļ�����Ŀ�ļ��е�·��
        $linkPath = $linkName.Replace($_.Name, "").TrimEnd("\\")

        # �����ǰ·������һ�μ�¼��·����ͬ���������ɸ��� items
        If (!($linkPath -eq $pPath)) {

            #���ɸ�������
			$titleContent = $null
            $titleContent = buildItems($linkPath, $dirPath)
			$newTocContent = $newTocContent + $titleContent

            # ���¸���
            $pPath = $linkPath
        }

        $sharps = getSharp($depth)

        $newTocContent = $newTocContent + ($sharps + "[" + $_.BaseName + "](" + ($linkName -replace "\\","/") + ")")
    }

	# �����Ŀ¼����index.md�����һ��Ŀ¼
	if(Test-Path ([System.IO.Path]::Combine($dirPath, "index.md")))
	{
		$newTocContent = @("# [����](index.md)") + $newTocContent
	}

	return $newTocContent
}

# ���ɸ�������
function buildItems($arg) {

	$linkPath = $arg[0]
	$base = $arg[1]

    $arr = $linkPath -split "\\"
	$content = @()

    for ($i = 0; $i -lt $arr.Length; $i++) {

        $_ = $arr[$i]

        # ��ȡ���
        $sharps = getSharp($i)

		$title = $null

		$indexMDFile = [System.IO.Path]::Combine($base,  $_, "index.md")

		if(Test-Path $indexMDFile)
		{
			$title = $sharps + "[" + $_ + "](" + $_ + "/" + "index.md)"
		}else
		{
			$title = $sharps + $_
		}

		# ����Ѿ����ڴ˱��⣬����
		if(-not($newTocContent -contains $title))
		{
			# �������Ƕ������⣬���һ����
			if($sharps -eq "# ")
			{
				$content = $content + "" + $title
			}
			else
			{
				$content = $content + $title
			}		
		}		
    }

	return $content
}

# ������Ȼ�ȡ # ����
function getSharp($depth) {
	$depth++
    $share = ""
    for ($i = 0; $i -lt $depth; $i++) {
        $share += "#"
    }

	return $share + " "
}

$newToc = buildToc($Directory);
$newToc | Out-File "utf8" -FilePath ([System.IO.Path]::Combine($Directory, "toc-temp.md"))