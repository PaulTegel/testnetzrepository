package exel;

import java.io.File;
import java.io.IOException;

import jxl.Cell;
import jxl.CellType;
import jxl.Sheet;
import jxl.Workbook;
import jxl.read.biff.BiffException;

public class ReadExcel {

	private String inputFile;

	public void setInputFile(String inputFile) {
		this.inputFile = inputFile;
	}

	public void read() throws IOException {
		File inputWorkbook = new File(inputFile);
		Workbook w;
		try {
			w = Workbook.getWorkbook(inputWorkbook);
			// Get the first sheet
			Sheet sheet = w.getSheet(0);
			// Loop over first 10 column and lines

			// sheet.getRows() 12
			for (int i = 0; i < 97; i++) {
				// for (int j = 0; j < sheet.getColumns(); j++) {
				System.out.print(i+1);
				for (int j = 0; j < 15; j++) {
					Cell cell = sheet.getCell(j, i);
					CellType type = cell.getType();
					if (type == CellType.LABEL) {
						// System.out.print(" " + j + ", " + i + ": " + cell.getContents());
						System.out.print("				" + cell.getContents());
					}

					if (type == CellType.NUMBER) {
						System.out.println("I got a number " + cell.getContents());
					}

				}
				System.out.println();
			}
		} catch (BiffException e) {
			e.printStackTrace();
		}
	}

	public static void main(String[] args) throws IOException {
		ReadExcel test = new ReadExcel();
		test.setInputFile("c:/develop/Paul_TF.xls");
		test.read();
	}

}