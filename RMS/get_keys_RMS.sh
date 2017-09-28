#!/bin/bash
function info()
{
echo ""
echo "Number 	Description 			Mnemonic

0 	Delete DS 			DELETE
1 	RSA/MD5 (deprecated, see 5) 	RSAMD5
2 	Diffie-Hellman 			DH
3 	DSA/SHA1 			DSA
4 	Reserved 	
5 	RSA/SHA-1 			RSASHA1
6 	DSA-NSEC3-SHA1 			DSA-NSEC3-SHA1
7 	RSASHA1-NSEC3-SHA1 		RSASHA1-NSEC3-SHA1
8 	RSA/SHA-256 			RSASHA256
9 	Reserved 		
10 	RSA/SHA-512 			RSASHA512
11 	Reserved 		
12 	GOST R 34.10-2001 		ECC-GOST
13 	ECDSA Curve P-256 with SHA-256 	ECDSAP256SHA256
14 	ECDSA Curve P-384 with SHA-384 	ECDSAP384SHA384
15 	Ed25519 			ED25519
16 	Ed448 				ED448
17-122 	Unassigned 				
123-251 Reserved"
}


info

echo "Start der Generierung"
date
echo ""
echo "domain.com"
echo "generate ZSK for zone domain.com"
dnssec-keygen -a RSASHA256 -b 2048 -r /dev/urandom -n ZONE domain.com
echo "ZSK key done"
echo ""
date
echo ""
echo ""
dnssec-keygen -a RSASHA256 -b 2048 -f KSK -r /dev/urandom -n ZONE domain.com
echo "KSK key done"
echo ""
date

echo "Ende"









