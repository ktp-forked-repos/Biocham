package fr.inria.contraintes.biocham.customComponents;


import java.awt.Color;
import java.awt.Cursor;
import java.awt.Graphics;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseMotionAdapter;

import javax.swing.JComponent;
import javax.swing.JLabel;
import javax.swing.UIManager;
import javax.swing.border.Border;
import javax.swing.border.EmptyBorder;

/*
 *  Simple implementation of a Glass Pane that will capture and ignore all
 *  events as well paint the glass pane to give the frame a "disabled" look.
 *
 *  The background color of the glass pane should use a color with an
 *  alpha value to create the disabled look.
 */


/**
 * Class thats creates the the plotting area for visualizing the numerical simulation results done by the biocham boolean simulator.
 * 
 * @author Dragana Jovanovska  
 */ 
public class DisabledGlassPane extends JComponent
	implements KeyListener
{
	private final static Border MESSAGE_BORDER = new EmptyBorder(10, 10, 10, 10);
	private JLabel message = new JLabel();

	public DisabledGlassPane()
	{
		//  Set glass pane properties

		setOpaque( false );
		Color base = UIManager.getColor("inactiveCaptionBorder");
		Color background;
		if(base!=null){
			background = new Color(base.getRed(), base.getGreen(), base.getBlue(), 128);
		}else{
			background = new Color(100, 130,222, 128);
		}
		
		setBackground( background );
		setLayout( new GridBagLayout() );

		//  Add a message label to the glass pane

		add(message, new GridBagConstraints());
		message.setOpaque(true);
		message.setBorder(MESSAGE_BORDER);

		//  Disable Mouse, Key and Focus events for the glass pane

		addMouseListener( new MouseAdapter() {} );
		addMouseMotionListener( new MouseMotionAdapter() {} );

		addKeyListener( this );

		setFocusTraversalKeysEnabled(false);
	}

	/*
	 *  The component is transparent but we want to paint the background
	 *  to give it the disabled look.
	 */
	@Override
	protected void paintComponent(Graphics g)
	{
		g.setColor( getBackground() );
		g.fillRect(0, 0, getSize().width, getSize().height);
	}

	/*
	 *  The	background color of the message label will be the same as the
	 *  background of the glass pane without the alpha value
	 */
	@Override
	public void setBackground(Color background)
	{
		super.setBackground( background );

		Color messageBackground = new Color(background.getRGB());
		message.setBackground( messageBackground );
	}
//
//  Implement the KeyListener to consume events
//
	public void keyPressed(KeyEvent e)
	{
		e.consume();
	}

	public void keyTyped(KeyEvent e) {}

	public void keyReleased(KeyEvent e)
	{
		e.consume();
	}

	/*
	 *  Make the glass pane visible and change the cursor to the wait cursor
	 *
	 *  A message can be displayed and it will be centered on the frame.
	 */
	public void activate(String text)
	{
		if  (text != null && text.length() > 0)
		{
			message.setVisible( true );
			message.setText( text );
			message.setForeground( getForeground() );
		}
		else
			message.setVisible( false );

		setVisible( true );
		setCursor(Cursor.getPredefinedCursor(Cursor.WAIT_CURSOR));
		requestFocusInWindow();
	}

	/*
	 *  Hide the glass pane and restore the cursor
	 */
	public void deactivate()
	{
		setCursor(null);
		setVisible( false );
	}
	
	public static void main(String[] args) {
		
		/*DisabledGlassPane glassPane = new DisabledGlassPane();
		JRootPane rootPane = SwingUtilities.getr
		rootPane.setGlassPane( glassPane );
		glassPane.activate("Please Wait...");
		
		JFrame f = new JFrame();
		f.setSize(800, 800);
		f.setDefaultCloseOperation(WindowConstants.EXIT_ON_CLOSE);
		f.setLayout(new BorderLayout());
		f.add(test1, BorderLayout.CENTER);
		f.setVisible(true);*/
	}
}
