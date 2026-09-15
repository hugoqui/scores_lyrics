using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using System.Windows.Forms; // Asegúrate de tener esta referencia
using System.Xml.Linq;

namespace ProyectorDesktop
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        private string? baseUrl;

        public MainWindow()
        {
            InitializeComponent();                                   
            this.WindowState = WindowState.Maximized;

            LoadConfiguration();
            webView.Source = new Uri($"{baseUrl}/panel/");

        }

        private void LoadConfiguration()
        {
            try
            {
                XDocument config = XDocument.Load("AppConfig.xml");
                baseUrl = config.Descendants("Setting")
                                .FirstOrDefault(s => s.Attribute("name")?.Value == "BaseUrl")?
                                .Attribute("value")?.Value;

                if (string.IsNullOrEmpty(baseUrl))
                {
                    System.Windows.MessageBox.Show("La URL base no está configurada.");
                }
            }
            catch (Exception ex)
            {
                System.Windows.MessageBox.Show($"Error al cargar la configuración: {ex.Message}");
            }
        }

        private FullScreenWindow? fullScreenWindow;

        private void proyectorButton_Click(object sender, RoutedEventArgs e)
        {
            if (fullScreenWindow == null || !fullScreenWindow.IsVisible)
            {
                fullScreenWindow = new FullScreenWindow(baseUrl!);

                // Obtener las pantallas conectadas
                var pantallas = Screen.AllScreens;

                if (pantallas.Length > 1) // Verifica que haya más de una pantalla
                {
                    // Establecer propiedades para abrir en la segunda pantalla
                    var segundaPantalla = pantallas[0]; // Asumiendo que quieres la segunda pantalla

                    // Establecer la propiedad WindowStartupLocation en Manual
                    fullScreenWindow.WindowStartupLocation = WindowStartupLocation.Manual;

                    // Establecer las propiedades Left y Top para posicionar la ventana en la segunda pantalla
                    fullScreenWindow.Left = segundaPantalla.Bounds.Width; // Posición X de la segunda pantalla
                    fullScreenWindow.Top = segundaPantalla.Bounds.Y;  // Posición Y de la segunda pantalla

                    // Ajustar el tamaño de la ventana si es necesario
                    fullScreenWindow.Width = segundaPantalla.Bounds.Width;
                    fullScreenWindow.Height = segundaPantalla.Bounds.Height;

                    fullScreenWindow.Show();
                }
                else
                {
                    System.Windows.MessageBox.Show("No hay una segunda pantalla conectada.");
                }
            }
            else
            {
                fullScreenWindow.Close();
            }
        }


    }
}