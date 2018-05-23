package digit;

public class HexadecimalMain {

	private static String CID3 = "cb:4b:63:7a:ff:ff";
	private static String CID4 = "ca:4a:63:7a:ff:ff";
	// private static String CID4 = "00:00:00:00:ff:ff";

	public static void main(String[] args) {

//		String hexNumber = "5";
//		int decimal = Integer.parseInt(hexNumber, 16);
//		System.out.println("Hex value(decimal) is " + decimal);
//
//		String[] b = CID3.split(":");
//		for (int i = b.length - 1; i > 0; i--) {
//
//			System.out.println("i: " + i);
//			System.out.println("b[" + i + "]: " + b[i]);
//
//			int dec = Integer.parseInt(b[i], 16);
//			dec++;
//
//			String hex = Integer.toHexString(dec);
//			b[i] = hex;
//
//			if (b[i].length() == 3) {
//				b[i] = "00";
//			} else {
//				break;
//			}
//			System.out.println("\n---\n");
//		}
//
//		String ret = "";
//		for (int i = 0; i < b.length; i++) {
//			if (i == 0) {
//				ret += b[i];
//			} else {
//				ret += ":" + b[i];
//			}
//		}

//		System.out.println("CID3: " + CID3);
//		System.out.println("+1:   " + ret + "\n\n\n");

//		for (int i = b.length; i > 0; i--) {
//			System.out.println((b.length - i) * 2);
//		}

		System.out.println("CID3: " + CID3);
		System.out.println("CID4: " + CID4);
		String max = getMax(CID3, CID4);
		System.out.println("---------------");
		System.out.println("max value: " + max);

		System.out.println("max value increased 1: " + increaseHex(max));

	}

	private static String increaseHex(String hexNumber) {
		String[] b = CID3.split(":");
		for (int i = b.length - 1; i > 0; i--) {

//			System.out.println("i: " + i);
//			System.out.println("b[" + i + "]: " + b[i]);

			int dec = Integer.parseInt(b[i], 16);
			dec++;

			String hex = Integer.toHexString(dec);
			b[i] = hex;

			if (b[i].length() == 3) {
				b[i] = "00";
			} else {
				break;
			}
//			System.out.println("\n---\n");
		}

		String ret = "";
		for (int i = 0; i < b.length; i++) {
			if (i == 0) {
				ret += b[i];
			} else {
				ret += ":" + b[i];
			}
		}
		return ret;
	}

	private static String getMax(String hexNumber1, String hexNumber2) {

		double digit1 = 0;
		double digit2 = 0;

		String[] b1 = hexNumber1.split(":");
		String[] b2 = hexNumber2.split(":");

		for (int i = b1.length - 1; i > 0; i--) {
			digit1 += Integer.parseInt(b1[i], 16) * Math.pow(16, (b1.length - i) * 2);
		}
		System.out.println("digit1: " + digit1);

		for (int i = b2.length - 1; i > 0; i--) {
			digit2 += Integer.parseInt(b2[i], 16) * Math.pow(16, (b2.length - i) * 2);
		}
		System.out.println("digit2: " + digit2);

		return digit1 > digit2 ? hexNumber1 : hexNumber2;
	}

}
