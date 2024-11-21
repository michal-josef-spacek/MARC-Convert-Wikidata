use strict;
use warnings;

use MARC::Convert::Wikidata::Utils qw(clean_publication_date);
use Test::More 'tests' => 481;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);
use Data::Dumper;

my @tests = (
    {
        input    => '2010',
        expected => '2010',
        option   => undef,
    },
    {
        input    => 'foo',
        expected => undef,
        option   => undef,
    },
    {
        input    => 's.a.',
        expected => undef,
        option   => undef,
    },
    {
        input    => 's. a.',
        expected => undef,
        option   => undef,
    },
    {
        input    => 'c2020',
        expected => '2020',
        option   => 'copyright',
    },
    {
        input    => '2020?',
        expected => '2020',
        option   => 'circa',
    },
    {
        input    => '[2020?]',
        expected => '2020',
        option   => 'circa',
    },
    {
        input    => '1950-1960',
        expected => '1950-1960',
        option   => undef,
    },
    {
        input    => '1950-',
        expected => '1950-',
        option   => undef,
    },
    {
        input    => '1994-[2002]',
        expected => '1994-2002',
        option   => undef,
    },
    {
        input    => '2002]',
        expected => '2002',
        option   => 'circa',
    },
    {
        input    => '(1861)',
        expected => '1861',
        option   => 'circa',
    },
    {
        input    => '(19--)',
        expected => '1900',
        option   => 'circa',
    },
    {
        input    => '(1927-1936)',
        expected => '1927-1936',
        option   => 'circa',
    },
    {
        input    => '(1930).',
        expected => '1930',
        option   => 'circa',
    },
    {
        input    => '℗2024',
        expected => '2024',
        option   => 'copyright',
    },
    {
        input    => '℗2023,',
        expected => '2023',
        option   => 'copyright',
    },
    {
        input    => '℗ 2014',
        expected => '2014',
        option   => 'copyright',
    },
    {
        input    => '℗2015-2016,',
        expected => '2015-2016',
        option   => 'copyright',
    },
    {
        input    => '℗1991 Multisonic,',
        expected => '1991',
        option   => 'copyright',
    },
    {
        input    => '℗202018',
        expected => '2020',
        option   => 'copyright',
    },
    {
        input    => '®2019',
        expected => '2024',
        option   => 'copyright',
    },
    {
        input    => '©c1920',
        expected => '1920',
        option   => 'copyright',
    },
    {
        input    => '©[2019]',
        expected => '2019',
        option   => 'copyright', #TODO: how to have circa and copyright together?
    },
    {
        input    => '©917',
        expected => undef,
        option   => 'copyright',
    },
    {
        input    => '©2024.',
        expected => '2024',
        option   => 'copyright',
    },
    {
        input    => '© 2023',
        expected => '2023',
        option   => 'copyright',
    },
    {
        input    => '©2016-',
        expected => '2016-',
        option   => 'copyright',
    },
    {
        input    => '©2021-2022',
        expected => '2021-2022',
        option   => 'copyright',
    },
    {
        input    => '©2017, ℗1951',
        expected => '2017',
        option   => 'copyright',
    },
    {
        input    => '©2017, ℗1951',
        expected => '2017',
        option   => 'copyright',
    },
    {
        input    => '©1993 ,',
        expected => '1993',
        option   => 'copyright',
    },
    {
        input    => '©',
        expected => undef,
        option   => 'copyright',
    },
    {
        input    => '©2021/2022',
        expected => '2021-2022',
        option   => 'copyright',
    },
    {
        input    => 'p[2013]',
        expected => '2013',
        option   => 'copyright',
    },
    {
        input    => 'p2015',
        expected => '2015',
        option   => 'copyright',
    },
    {
        input    => 'p2014, p2006, p2007',
        expected => '2014',
        option   => 'copyright',
    },
    {
        input    => 'p2014, p2006',
        expected => '2014',
        option   => 'copyright',
    },
    {
        input    => 'p2014, [2010]',
        expected => '2014',
        option   => 'copyright',
    },
    {
        input    => 'p2014, 2008',
        expected => '2014',
        option   => 'copyright',
    },
    {
        input    => 'p2010, c2010',
        expected => '2010',
        option   => 'copyright',
    },
    {
        input    => 'p2008, 1991, 1993',
        expected => '2008',
        option   => 'copyright',
    },
    {
        input    => 'p2002, [c1983]',
        expected => '2002',
        option   => 'copyright',
    },
    {
        input    => 'p1962-2001',
        expected => '1962-2001',
        option   => 'copyright',
    },
    {
        input    => 'p2003/2004',
        expected => '2003-2004',
        option   => 'copyright',
    },
    {
        input    => 'p 1996',
        expected => '1996',
        option   => 'copyright',
    },
    {
        input    => 'p2010 [i.e. 2011]',
        expected => '2011',
        option   => 'circa',
    },
    {
        input    => 'okolo r.1980]',
        expected => '1980',
        option   => 'circa',
    },
    {
        input    => 'okolo r. 1980]',
        expected => '1980',
        option   => 'circa',
    },
    {
        input    => 'okolo 1940]',
        expected => '1940',
        option   => 'circa',
    },



    {
        input    => 'Český hudební fond, 1974',
        expected => '1974',
        option   => undef,
    },
    {
        input    => '3 s.',
        expected => undef,
        option   => undef,
    },
    {
        input    => '4°',
        expected => undef,
        option   => undef,
    },
    {
        input    => '2014/2015',
        expected => '2014-2015',
        option   => undef,
    },
    {
        input    => '(1980 ?)',
        expected => '1980',
        option   => 'circa',
    },
    {
        input    => '(c1916)',
        expected => '1916',
        option   => 'circa',
    },
    {
        input    => '(ca1863)',
        expected => '1863',
        option   => 'circa',
    },
    {
        input    => '(cca. 1863)',
        expected => '1863',
        option   => 'circa',
    },
    {
        input    => '(mezi 1906 a 1939?]',
        expected => '1906-1939',
        option   => 'circa',
    },
    {
        input    => '1392 [i.e. 1932]',
        expected => '1932',
        option   => 'circa',
    },
    {
        input    => '1804 [i.e. 1806?]',
        expected => '1806',
        option   => 'circa',
    },
    {
        input    => '1536, [spr. 1936]',
        expected => '1936',
        option   => 'circa',
    },
    {
        input    => '16980',
        expected => '1698',
        option   => undef,
    },
    {
        input    => '1791-1807]',
        expected => '1791-1807',
        option   => 'circa',
    },
    {
        input    => '18--',
        expected => '1800',
        option   => 'circa',
    },
    {
        input    => '18-- ?]',
        expected => '1800',
        option   => 'circa',
    },
    {
        input    => '18-- ]',
        expected => '1800',
        option   => 'circa',
    },
    {
        input    => '18--?',
        expected => '1800',
        option   => 'circa',
    },
    {
        input    => '18--?]',
        expected => '1800',
        option   => 'circa',
    },
    {
        input    => '18--]',
        expected => '1800',
        option   => 'circa',
    },
    {
        input    => '183-?]',
        expected => '1830',
        option   => 'circa',
    },
    {
        input    => '1801.',
        expected => '1801',
        option   => undef,
    },
    {
        input    => '1801?]',
        expected => '1801',
        option   => 'circa',
    },
    {
        input    => '1828 - 1838',
        expected => '1828-1838',
        option   => undef,
    },
    {
        input    => '1825,',
        expected => '1825',
        option   => undef,
    },
    {
        input    => '1817-[1824?]',
        expected => '1817-1824',
        option   => 'circa',
    },
    {
        input    => '1832-8',
        expected => '1832-1838',
        option   => undef,
    },
    {
        input    => '1835-1836.',
        expected => '1835-1836',
        option   => undef,
    },
    {
        input    => '1838, [i.e. 1938]',
        expected => '1938',
        option   => 'circa',
    },
    {
        input    => '183[5?]',
        expected => '1835',
        option   => 'circa',
    },
    {
        input    => '1842 ]',
        expected => '1842',
        option   => 'circa',
    },
    {
        input    => '1845 :',
        expected => '1845',
        option   => undef,
    },
    {
        input    => '1848-18--?',
        expected => '1848-',
        option   => undef,
    },
    {
        input    => '1848-[18--]',
        expected => '1848-',
        option   => undef,
    },
    {
        input    => '185-]',
        expected => '1850',
        option   => 'circa',
    },
    {
        input    => '1856, (na ob. 1862)',
        expected => '1856',
        option   => undef,
    },
    {
        input    => '1862 ;',
        expected => '1862',
        option   => undef,
    },
    {
        input    => '1867 [tj. 1863]',
        expected => '1863',
        option   => 'circa',
    },
    {
        input    => '1868 [i.e. 1867]',
        expected => '1867',
        option   => 'circa',
    },
    {
        input    => '1874, [na ob.] 1876',
        expected => '1874',
        option   => undef,
    },
    {
        input    => '1882 [i.e.1894]',
        expected => '1894',
        option   => undef,
    },
    {
        input    => '1880, c1872',
        expected => '1880',
        option   => undef,
    },
    {
        input    => '1878 -1880',
        expected => '1878-1880',
        option   => undef,
    },
    {
        input    => '1885-?',
        expected => '1885-',
        option   => undef,
    },
    {
        input    => '1890-1900?]',
        expected => '1890-1900',
        option   => 'circa',
    },
    {
        input    => '1892- 1893',
        expected => '1892-1893',
        option   => undef,
    },
    {
        input    => '1893-96',
        expected => '1893-1896',
        option   => undef,
    },
    {
        input    => '1844 nebo 1845]',
        expected => '1844',
        option   => 'circa',
    },
    {
        input    => '1901 nebo 1902',
        expected => '1901',
        option   => 'circa',
    },
    {
        input    => '1903 [nebo 1904]',
        expected => '1903',
        option   => 'circa',
    },
    {
        input    => '1903 nebo 1904?]',
        expected => '1903',
        option   => 'circa',
    },
    {
        input    => '1903[nebo 1904]',
        expected => '1903',
        option   => 'circa',
    },
    {
        input    => '1906 nebo1907',
        expected => '1906',
        option   => 'circa',
    },
    {
        input    => '1914] nebo 1915',
        expected => '1914',
        option   => 'circa',
    },
    {
        input    => '1916 nebo [1917]',
        expected => '1916',
        option   => 'circa',
    },
    {
        input    => '[1804 nebo 1805]',
        expected => '1804',
        option   => 'circa',
    },
    {
        input    => '[1835 nebo1836]',
        expected => '1835',
        option   => 'circa',
    },
    {
        input    => '[1896 nebo 1897?]',
        expected => '1896',
        option   => 'circa',
    },
    # TODO: Is this even possible to implement correctly?
    {
        input    => '[1905 nebo 1906?-mezi 1908 a 1910?]',
        expected => '1905-1910',
        option   => 'circa',
    },
    {
        input    => '{1930?]',
        expected => '1930',
        option   => 'circa',
    },
    {
        input    => 'v1933',
        expected => '1933',
        option   => undef,
    },
    {
        input    => 's.a. [ca1896]',
        expected => '1896',
        option   => 'circa',
    },
    {
        input    => 's. a. (c1936)',
        expected => '1936',
        option   => 'copyright',
    },
    {
        input    => 'rozmnož. [1947]',
        expected => '1947',
        option   => 'circa',
    },
    {
        input    => 'rozmnož. 1947',
        expected => '1947',
        option   => undef,
    },
    {
        input    => 'rozmn. [1947]',
        expected => '1947',
        option   => 'circa',
    },
    {
        input    => 'rozmn. 1947',
        expected => '1947',
        option   => undef,
    },
    {
        input    => 'přetisk červenec 1944]',
        expected => '1944',
        option   => 'circa',
    },
    {
        input    => 'přetisk1939',
        expected => '1939',
        option   => undef,
    },
    {
        input    => 'přetisk z r. 1933',
        expected => '1933',
        option   => undef,
    },
    {
        input    => 'přetisk [1948-]',
        expected => '1948-',
        option   => 'circa',
    },
    {
        input    => 'přetisk [1948]',
        expected => '1948-',
        option   => 'circa',
    },
    {
        input    => 'přetisk 1948]',
        expected => '1948-',
        option   => 'circa',
    },
    {
        input    => 'přetisk 1949',
        expected => '1949',
        option   => undef,
    },
    {
        input    => 'přet. [1949-]',
        expected => '1949-',
        option   => 'circa',
    },
    {
        input    => 'přet. [1942]',
        expected => '1942',
        option   => 'circa',
    },
    {
        input    => 'přet. 1946',
        expected => '1946',
        option   => undef,
    },
    {
        input    => 'přet. 1935, po 1931',
        expected => '1935',
        option   => undef,
    },
    {
        input    => 'léta Páně 1937',
        expected => '1937',
        option   => undef,
    },
    {
        input    => 'kolem roku 1930',
        expected => '1930',
        option   => 'circa',
    },
    {
        input    => 'kolem r.1930]',
        expected => '1930',
        option   => 'circa',
    },
    {
        input    => 'kolem r. 1980]',
        expected => '1980',
        option   => 'circa',
    },
    {
        input    => 'kolem 1954]',
        expected => '1954',
        option   => 'circa',
    },
    {
        input    => 'kol. r. 1970]',
        expected => '1970',
        option   => 'circa',
    },
    {
        input    => 'cca 1938',
        expected => '1938',
        option   => 'circa',
    },
    {
        input    => 'cca 1923]',
        expected => '1923',
        option   => 'circa',
    },
    {
        input    => 'ca1888',
        expected => '1888',
        option   => 'circa',
    },
    {
        input    => 'ca. 1888]',
        expected => '1888',
        option   => 'circa',
    },
    {
        input    => 'ca 1973]',
        expected => '1973',
        option   => 'circa',
    },
    {
        input    => 'ca 1894',
        expected => '1894',
        option   => 'circa',
    },
    {
        input    => 'c[přetisk 1944]',
        expected => '1944',
        option   => 'copyright', #TODO + circa
    },
    {
        input    => 'c[2014]',
        expected => '2014',
        option   => 'copyright', #TODO + circa
    },
    {
        input    => 'c930.',
        expected => undef,
        option   => 'copyright',
    },
    {
        input    => 'c2015-',
        expected => '2015-',
        option   => 'copyright',
    },
    {
        input    => 'ca1888',
        expected => '1888',
        option   => 'copyright',
    },
    {
        input    => 'c2014-c2015',
        expected => '2014-2015',
        option   => 'copyright',
    },
    {
        input    => 'c2014-[2019]',
        expected => '2014-2019',
        option   => 'copyright', #TODO + circa
    },
    {
        input    => 'c2014, p1997',
        expected => '2014',
        option   => 'copyright',
    },
    {
        input    => 'c2013]',
        expected => '2013',
        option   => 'copyright', #TODO - circa
    },
    {
        input    => 'c2013-2014',
        expected => '2013-2014',
        option   => 'copyright',
    },
    {
        input    => 'c2012-[2023?]',
        expected => '2012-2023',
        option   => 'copyright', # TODO + circa
    },
    {
        input    => 'c2011 [i.e. 2012]',
        expected => '2012',
        option   => 'circa',
    },
    {
        input    => 'c2007 [i.e. c2008]',
        expected => '2008',
        option   => 'copyright', # TODO + circa
    },
    {
        input    => 'c2007 [i.e. 2009?]',
        expected => '2009',
        option   => 'circa',
    },
    {
        input    => 'c2008, p1965-1989',
        expected => '2008',
        option   => 'copyright',
    },
    {
        input    => 'c2005-2011?',
        expected => '2005-2011',
        option   => 'copyright', # TODO + circa
    },
    {
        input    => 'c2005,',
        expected => '2005',
        option   => 'copyright',
    },
    {
        input    => 'c2005 dopolnitelnyj tiraž',
        expected => '2005',
        option   => 'copyright',
    },
    {
        input    => 'c2002]-',
        expected => '2002',
        option   => 'copyright', # TODO + circa
    },
    {
        input    => 'c2002-c2005]',
        expected => '2002-2005',
        option   => 'copyright', # TODO + circa
    },
    {
        input    => 'c2000, 2008',
        expected => '2008',
        option   => undef,
    },
    {
        input    => 'c1982 [v tir. nesprávně] 1980',
        expected => '1982',
        option   => 'copyright',
    },
    {
        input    => 'cop.1946',
        expected => '1946',
        option   => 'copyright',
    },
    {
        input    => 'cop. 1922',
        expected => '1922',
        option   => 'copyright',
    },
    {
        input    => 'cop [1925]',
        expected => '2005',
        option   => 'copyright', # TODO + circa
    },
    {
        input    => 'cop 1922',
        expected => '1922',
        option   => 'copyright',
    },
    {
        input    => 'c 2004',
        expected => '2004',
        option   => 'copyright',
    },
    {
        input    => 'c1962/1964',
        expected => '1962-1964',
        option   => 'copyright',
    },
    {
        input    => 'c1921 [přetisk 1946]',
        expected => '1921',
        option   => 'copyright',
    },
    {
        input    => 'c2005',
        expected => '2005',
        option   => 'copyright',
    },
    {
        input    => 'c192',
        expected => undef,
        option   => 'copyright',
    },
    {
        input    => 'c1917-23',
        expected => '1917-1923',
        option   => 'copyright',
    },
    {
        input    => 'c 1910 - 1923',
        expected => '1910-1923',
        option   => 'copyright',
    },
    {
        input    => 'asi 1911',
        expected => '1911',
        option   => 'circa',
    },
    {
        input    => 'asi 1901]',
        expected => '1901',
        option   => 'circa',
    },
    {
        input    => ']1939]',
        expected => '1939',
        option   => 'circa',
    },
    {
        input    => ']1954',
        expected => '1954',
        option   => 'circa',
    },
    {
        input    => '[úv.: 1928]',
        expected => '1928',
        option   => 'circa',
    },
    {
        input    => '[přetisk říjen 1943]',
        expected => '1943',
        option   => 'circa',
    },
    {
        input    => '[přetisk 1944], c1943',
        expected => '1944',
        option   => 'circa',
    },
    {
        input    => '[p2006]',
        expected => '2006',
        option   => 'copryright', #TODO + circa
    },
    {
        input    => '[okolo r. 1937]',
        expected => '1937',
        option   => 'circa',
    },
    {
        input    => '[okolo  1937]',
        expected => '1937',
        option   => 'circa',
    },
    {
        input    => '[kolem roku 1973]',
        expected => '1973',
        option   => 'circa',
    },
    {
        input    => '[kolem r. 1970]',
        expected => '1970',
        option   => 'circa',
    },
    {
        input    => '[kolem 1940?]',
        expected => '1940',
        option   => 'circa',
    },
    {
        input    => '[kol. r. 1930]',
        expected => '1930',
        option   => 'circa',
    },
    {
        input    => '[cca1882]',
        expected => '1882',
        option   => 'circa',
    },
    {
        input    => '[cca 1938]',
        expected => '1938',
        option   => 'circa',
    },
    {
        input    => '[cca 1920-1931]',
        expected => '1920-1931',
        option   => 'circa',
    },
    {
        input    => '[ca1888]',
        expected => '1888',
        option   => 'circa',
    },
    {
        input    => '[ca. 1941]',
        expected => '1941',
        option   => 'circa',
    },
    {
        input    => '[ca 2002]',
        expected => '1954',
        option   => 'circa',
    },
    {
        input    => '[ca 1875?]',
        expected => '1875',
        option   => 'circa',
    },
    {
        input    => '[c2010-c2011]',
        expected => '2010-2011',
        option   => 'copyright', # TODO + circa
    },
    {
        input    => '[c1976]',
        expected => '1976',
        option   => 'copyright', # TODO + circa
    },
    {
        input    => '[c2009-]',
        expected => '2009-',
        option   => 'copyright', # TODO + circa
    },
    {
        input    => '[c2004]-',
        expected => '1954',
        option   => 'copyright',
    },
    {
        input    => '[c 1827]',
        expected => '1827',
        option   => 'copyright', # TODO + circa
    },
    {
        input    => '[c1908, 1924?]',
        expected => '1924',
        option   => 'circa',
    },
    {
        input    => '[asi] 1920',
        expected => '1920',
        option   => 'circa',
    },
    {
        input    => '[asi r. 1949]',
        expected => '1949',
        option   => 'circa',
    },
    {
        input    => '[asi 1990]',
        expected => '1990',
        option   => 'circa',
    },
    {
        input    => '[asi 1934-1935]',
        expected => '1934-1935',
        option   => 'circa',
    },
    {
        input    => '[2020]',
        expected => '2020',
        option   => 'circa',
    },
    {
        input    => '[2020:]',
        expected => '2020',
        option   => 'copyright',
    },
    {
        input    => '[2024]-',
        expected => '2024-',
        option   => 'circa',
    },
    {
        input    => '[2023?]-',
        expected => '2023-',
        option   => 'circa',
    },
    {
        input    => '[2023-2024]',
        expected => '2023-2024',
        option   => 'circa',
    },
    {
        input    => '[2022?]-2023',
        expected => '2022-2023',
        option   => 'circa',
    },
    {
        input    => '[2021]-2022',
        expected => '2021-2022',
        option   => 'circa',
    },
    {
        input    => '[2020]-[2023]',
        expected => '2020-2023',
        option   => 'circa',
    },
    {
        input    => '[2020?-2021?]',
        expected => '2020-2021',
        option   => 'circa',
    },
    {
        input    => '[2017-2020?]',
        expected => '2017-2020',
        option   => 'circa',
    },
    {
        input    => '[2017?-2020]',
        expected => '2017-2020',
        option   => 'circa',
    },
    {
        input    => '[2019-]',
        expected => '2019-',
        option   => 'circa',
    },
    {
        input    => '[2016]-[2020?]',
        expected => '2016-2020',
        option   => 'circa',
    },
    {
        input    => '[2016?]-[2019?]',
        expected => '2016-2019',
        option   => 'circa',
    },
    {
        input    => '[2015?]-[2016]',
        expected => '2015-2016',
        option   => 'circa',
    },
    {
        input    => '[2015?]-2018?',
        expected => '2015-2%18',
        option   => 'circa',
    },
    {
        input    => '[20]21',
        expected => '2021',
        option   => 'circa',
    },
    {
        input    => '[2014], p2013',
        expected => '2014',
        option   => 'circa',
    },
    {
        input    => '[2010?], c2002',
        expected => '2010',
        option   => 'circa',
    },
    {
        input    => '[2014], c2013',
        expected => '2014',
        option   => 'circa',
    },
    {
        input    => '[2016?- 2022?]',
        expected => '2016-2022',
        option   => 'circa',
    },
    {
        input    => '[2014?- 2022]',
        expected => '2014-2022',
        option   => 'circa',
    },
    {
        input    => '[2015?] -',
        expected => '2015-',
        option   => 'circa',
    },
    {
        input    => '[2014], 2008',
        expected => '2014',
        option   => 'circa',
    },
    {
        input    => '[2010] -2017',
        expected => '2010-2017',
        option   => 'circa',
    },
    {
        input    => '[1996]- 2004',
        expected => '1996-2004',
        option   => 'circa',
    },
    {
        input    => '[2011]-2021?',
        expected => '2011-2021',
        option   => 'circa',
    },
    {
        input    => '[2009]-?',
        expected => '2009-',
        option   => 'circa',
    },
    {
        input    => '[2008] -',
        expected => '2008-',
        option   => 'circa',
    },
    {
        input    => '[2010?-]',
        expected => '2010-',
        option   => 'circa',
    },
    {
        input    => '[Přetisk 1949]',
        expected => '1949',
        option   => 'circa',
    },
    {
        input    => '[Přetisk1941]',
        expected => '1941',
        option   => 'circa',
    },
    {
        input    => '[Otisk 1932]',
        expected => '1932',
        option   => 'circa',
    },
    {
        input    => '[5.V.1945-1946]',
        expected => '1945-1946',
        option   => 'circa',
    },
    {
        input    => '[2014?] tisk',
        expected => '2014',
        option   => 'circa',
    },
    {
        input    => '[2010 nabo 2011]',
        expected => '2010',
        option   => 'circa',
    },
    {
        input    => '[2007?',
        expected => '2007',
        option   => 'circa',
    },
    {
        input    => '[2007-]?',
        expected => '2007-',
        option   => 'circa',
    },
    {
        input    => '[2006]0',
        expected => '2006',
        option   => 'circa',
    },
    {
        input    => '[2005].',
        expected => '2005',
        option   => 'circa',
    },
    {
        input    => '[2005?]- 2013',
        expected => '2005-2013',
        option   => 'circa',
    },
    {
        input    => '[2005?-2009',
        expected => '2005-2009',
        option   => 'circa',
    },
    {
        input    => '[2004], p2003(!)',
        expected => '2004',
        option   => 'circa',
    },
    {
        input    => '[2004?[elektronický zdroj]-',
        expected => '2004-',
        option   => 'circa',
    },
    {
        input    => '[2004--2007?]',
        expected => '2004-2007',
        option   => 'circa',
    },
    {
        input    => '[2003], c2004 [sic]',
        expected => '2003',
        option   => 'circa',
    },
    {
        input    => '[2001-?]',
        expected => '2001-',
        option   => 'circa',
    },
    {
        input    => '[2002-',
        expected => '2002-',
        option   => 'circa',
    },
    {
        input    => '[2001_2005]',
        expected => '2001-2005',
        option   => 'circa',
    },
    {
        input    => '[2001?]-:',
        expected => '2001-',
        option   => 'circa',
    },
    {
        input    => '[2001)',
        expected => '2001',
        option   => 'circa',
    },
    {
        input    => '[2000], v tiráži chybně 1997, c1994',
        expected => '2000',
        option   => 'circa',
    },
    {
        input    => '[2000?] :',
        expected => '2000',
        option   => 'circa',
    },
    {
        input    => '[1997], p1983, 1985',
        expected => '1997',
        option   => 'circa',
    },
    {
        input    => '[1995?], p1982',
        expected => '1995',
        option   => 'circa',
    },
    {
        input    => '[1990]-2001]',
        expected => '1990-2001',
        option   => 'circa',
    },
    {
        input    => '[1987]?',
        expected => '1987',
        option   => 'circa',
    },
    {
        input    => '[1985 ?]',
        expected => '1985',
        option   => 'circa',
    },
    {
        input    => '[1978, na tit. listu nespr.] 1974',
        expected => '1978.',
        option   => 'circa',
    },
    {
        input    => 'před rokem 1961]',
        expected => '1961',
        option   => 'latest', # TODO: Implement latest/earliest
    },
    {
        input    => 'před r.1972]',
        expected => '1972',
        option   => 'latest',
    },
    {
        input    => 'před r. 1980]',
        expected => '1980',
        option   => 'latest',
    },
    {
        input    => 'po r.1970]',
        expected => '1970',
        option   => 'earliest',
    },
    {
        input    => 'mezi r. 1950 a 1960]',
        expected => '1950-1960',
        option   => 'latest/earliest',
    },
);

my $input;
my $ret;
my $ret_option;

for my $test (@tests) {
    $input = decode_utf8($test->{input});
    ($ret, $ret_option) = clean_publication_date($input);
    is($ret, $test->{expected}, encode_utf8("Publication date '$input' after cleanup"));
    is($ret_option, $test->{option}, encode_utf8("Publication date '$input' option."));
};

