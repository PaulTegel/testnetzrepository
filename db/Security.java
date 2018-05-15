package sqlite;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public class Security {

	private static final String url = "jdbc:sqlite:/root/temp/konnektor_db/protocol_security.db";
	private static final String url2 = "jdbc:sqlite:/root/temp/konnektor_db/protocol_security-2.db";

	private Connection connect() {
		// SQLite connection string
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
			conn = DriverManager.getConnection(url);
		} catch (SQLException e) {
			System.out.println(e.getMessage());
		}
		return conn;
	}

	/**
	 * select all rows in the warehouses table
	 */
	public void selectAll() {

		// delete(25236, 1299137248);

		// System.exit(0);

		String sql = "SELECT Id, Timestamp, Severity, Type, Code, Message, TaskGuid  FROM Protocol";

		try (Connection conn = this.connect();
				Statement stmt = conn.createStatement();
				ResultSet rs = stmt.executeQuery(sql))

		{

			// loop through the result set
			while (rs.next()) {

				System.out.println("\n");

				System.out.println(rs.getRow());

				System.out.println(rs.getInt("Id") + "\t" + rs.getInt("Timestamp") + "\t" + rs.getInt("Severity") + "\t"
						+ rs.getInt("Type") + "\t" + rs.getInt("Code") + "\t" + rs.getString("Message") + "\t"
						+ rs.getString("TaskGuid"));
				
				
				deleteRow(rs);
				System.exit(0);;
				
			}
		} catch (SQLException e) {
			System.out.println(e.getMessage());
		}
	}

	/**
	 * @param args
	 *            the command line arguments
	 */
	public static void main(String[] args) {
		Security app = new Security();
		app.selectAll();
	}

	// Id, Timestamp, Severity, Type, Code, Message, TaskGuid
	public void deleteRow(ResultSet rs) {
		String sql = "";
		try {
			String message = "\"" + rs.getString("Message") + "\"";
			System.out.println("message: " + message);
			
			
			sql = "DELETE FROM Protocol WHERE id = " + rs.getInt("Id") + " AND Timestamp = "
					+ rs.getInt("Timestamp") + " AND Severity = " + rs.getInt("Severity") + " AND Type = "
							+ rs.getInt("Type") + " AND Code = " + rs.getInt("Code") + " AND Message = "
							+ message + " AND TaskGuid = " + rs.getString("TaskGuid");
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
//			pstmt.executeUpdate();

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

}
