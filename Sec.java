package sqlite;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;

public class Sec {

	private static final String url2 = "jdbc:sqlite:/root/temp/Konnektor_db_select/protocol_security_b.db";
	private static final String url = "jdbc:sqlite:/root/temp/Konnektor_db_select/protocol_security_b_ende.db";

	private int zahl;
	private static ArrayList<String> erste;

	public static void main(String[] args) {
		
		long begin = System.currentTimeMillis();
		
		
		Sec app = new Sec();
		app.erste = new ArrayList<String>();
		app.selectAll();
		System.out.println("app.erste.size(): " + app.erste.size());

		
		
		ArrayList<String> al = app.getNewEntry();
		System.out.println("al.size()" + al.size());
		
		System.out.println("*********************************************************************");
		
		ArrayList<String> delta = new ArrayList<String>();

		for (String v : al) {
		    if (erste.contains(v)) {
		    } else {
		        delta.add(v);
		    }
		}
		
		System.out.println("delta.size(): " + delta.size());
		
		long ende = System.currentTimeMillis();
		
		System.out.println("Dauer " + ( ende - begin ) / 1000 + " Sekunden");
	}

	public ArrayList<String> getNewEntry() {

		System.out.println(zahl);
		String sql = "SELECT Id, Timestamp, Severity, Type, Code, Message, TaskGuid  FROM Protocol";
		
		int ind = 0;
		
		ArrayList<String> ret = new ArrayList<String>();
		
		
		try (Connection conn = this.connect2();
				Statement stmt2 = conn.createStatement();
				ResultSet rs2 = stmt2.executeQuery(sql))

		{

			while (rs2.next()) {
				
				ind++;
				String ss = rs2.getInt("Id") + "\t" + rs2.getInt("Timestamp") + "\t" + rs2.getInt("Severity") + "\t"
						+ rs2.getInt("Type") + "\t" + rs2.getInt("Code") + "\t" + rs2.getString("Message") + "\t"
						+ rs2.getString("TaskGuid");

				ret.add(ss);

			}
			System.out.println("ind: " + ind);
		} catch (SQLException e) {
			System.out.println(e.getMessage());
		}
		System.out.println(zahl);
		
		return ret;
	}

	public void selectAll() {

		String sql = "SELECT Id, Timestamp, Severity, Type, Code, Message, TaskGuid  FROM Protocol";

		try (Connection conn = this.connect();
				Statement stmt = conn.createStatement();
				ResultSet rs = stmt.executeQuery(sql))

		{
			while (rs.next()) {

				zahl = rs.getRow();

				String ss = rs.getInt("Id") + "\t" + rs.getInt("Timestamp") + "\t" + rs.getInt("Severity") + "\t"
						+ rs.getInt("Type") + "\t" + rs.getInt("Code") + "\t" + rs.getString("Message") + "\t"
						+ rs.getString("TaskGuid");
				
				erste.add(ss);

			}

			rs.close();

		} catch (SQLException e) {
			System.out.println(e.getMessage());
		}

		System.out.println("zahl1: " + zahl);
	}

	// Id, Timestamp, Severity, Type, Code, Message, TaskGuid
	public void deleteRow(ResultSet rs) {
		String sql = "";
		try {
			String message = "\"" + rs.getString("Message") + "\"";
			System.out.println("message: " + message);

			sql = "DELETE FROM Protocol WHERE id = " + rs.getInt("Id") + " AND Timestamp = " + rs.getInt("Timestamp")
					+ " AND Severity = " + rs.getInt("Severity") + " AND Type = " + rs.getInt("Type") + " AND Code = "
					+ rs.getInt("Code") + " AND Message = " + message + " AND TaskGuid = " + rs.getString("TaskGuid");
		} catch (SQLException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		}

		System.out.println(sql);

		try (Connection conn = this.connect(); PreparedStatement pstmt = conn.prepareStatement(sql)) {

			// set the corresponding param
			pstmt.setInt(1, rs.getInt("Id"));
			pstmt.setInt(2, rs.getInt("Timestamp"));
			pstmt.setInt(3, rs.getInt("Severity"));
			pstmt.setInt(4, rs.getInt("Type"));
			pstmt.setInt(5, rs.getInt("Code"));

			pstmt.setString(6, rs.getString("Message"));
			pstmt.setString(7, rs.getString("TaskGuid"));

			System.out.println(sql);

			// execute the delete statement
			// pstmt.executeUpdate();

		} catch (SQLException e) {
			System.out.println(e.getMessage());
		}
	}

	public void delete(int id, int timestamp) {
		String sql = "DELETE FROM Protocol WHERE id = ? AND Timestamp = ?";

		try (Connection conn = this.connect(); PreparedStatement pstmt = conn.prepareStatement(sql)) {

			// set the corresponding param
			pstmt.setInt(1, id);
			// execute the delete statement
			pstmt.executeUpdate();

		} catch (SQLException e) {
			System.out.println(e.getMessage());
		}
	}

	private Connection connect() {
		Connection conn = null;
		try {
			conn = DriverManager.getConnection(url);
		} catch (SQLException e) {
			System.out.println(e.getMessage());
		}
		return conn;

	}

	private Connection connect2() {

		Connection conn = null;
		try {
			conn = DriverManager.getConnection(url2);
		} catch (SQLException e) {
			System.out.println(e.getMessage());
		}
		return conn;
	}
}
