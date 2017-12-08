BEGIN {
		FS="\n"
		RS="# "
		print "<!DOCTYPE html>"
		print "<html>"
		print "<head>"
		print "<meta charset=\"UTF-8\">"
		print "<title>Dev And Tech Ops Host Status</title>"
		print "<style>"
		print "table {"
		print "    font-family: arial, sans-serif;"
		print "    border-collapse: collapse;"
		print "    width: 100%;"
		print "}"
	  print ""
		print "td, th {"
		print "    border: 1px solid #dddddd;"
		print "    text-align: left;"
		print "    padding: 8px;"
		print "}"
	  print ""
		print "td.red {"
		print "  background-color: red;"
    print "  color: white;"
		print "  text-align: center;"
		print "}"
		print ""
		print "td.green {"
		print "  background-color: green;"
    print "  color: white;"
		print "  text-align: center;"
		print "}"
		print "tr:nth-child(even) {"
		print "    background-color: #dddddd;"
		print "}"
		print "</style>"
		print "</head>"
		print "<body>"
}

# Body
{
		if ( $1 != "" ) {
				print "<table style=\"width:100%\">"
        print "<tr>"
        print "  <th colspan=\"5\">"
        print "    <h3>", $1, "</h3>"
        print "  </th>"
        print "</tr>"
				print "<tr>"
				print "	<th>IP</th>"
				print "	<th>Hostname</th>"
				print "	<th>Ansible Ping</th>"
				print "	<th>SSH</th>"
				print "	<th>Ping</th>"
				print "</tr>"

				x = 2
				while ( x < NF ) {
						print "<tr>"
						split($x, host, " ")
						print "  <td style=\"width:20%\">" host[1] "</td>"
						print "  <td style=\"width:30%\">" host[2] "</td>"
            if ( host[3] == "yes" ) {
										print "  <td class=\"green\" style=\"width:16.67%\"><b>" host[3] "</b></td>"
						}
						else {
								print "  <td class=\"red\" style=\"width:16.67%\"><b>" host[3] "</b></td>"
						}
						if ( host[4] == "yes" ) {
								print "  <td class=\"green\" style=\"width:16.66%\"><b>" host[4] "</b></td>"
						}
						else {
								print "  <td class=\"red\" style=\"width:16.66%\"><b>" host[4] "</b></td>"
						}
						if ( host[5] == "yes" ) {
								print "  <td class=\"green\" style=\"width:16.66%\"><b>" host[5] "</b></td>"
						}
						else {
								print "  <td class=\"red\" style=\"width:16.66%\"><b>" host[5] "</b></td>"
						}
						print "</tr>"
						x++
				}
				print "</table>"
        print "<br />"
		}
}

END {
		print "</body>"
		print "</html>"
}
