package es.lifevit.sdk.sampleapp.activities;

import android.content.DialogInterface;
import android.os.Bundle;
import android.text.method.ScrollingMovementMethod;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;

import java.util.ArrayList;
import java.util.Calendar;

import es.lifevit.sdk.LifevitSDKConstants;
import es.lifevit.sdk.LifevitSDKManager;
import es.lifevit.sdk.LifevitSDKUserData;
import es.lifevit.sdk.bracelet.LifevitSDKResponse;
import es.lifevit.sdk.bracelet.LifevitSDKVitalECGData;
import es.lifevit.sdk.bracelet.LifevitSDKVitalECGWaveform;
import es.lifevit.sdk.bracelet.LifevitSDKVitalPeriod;
import es.lifevit.sdk.listeners.LifevitSDKBraceletVitalListener;
import es.lifevit.sdk.listeners.LifevitSDKDeviceListener;
import es.lifevit.sdk.sampleapp.R;
import es.lifevit.sdk.sampleapp.SDKTestApplication;

//Libraries needed for new SDK improvements
/**
* Some imports of libraries needed in the improvement of SDK for DyCare company
*/
import android.os.Environment;
import es.lifevit.sdk.bracelet.LifevitSDKHeartbeatData;
import es.lifevit.sdk.LifevitSDKOximeterData;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Timer;
import java.util.TimerTask;

/**
 * This class was developed for lifevit company as a SDK of the Vital device. In order to do an
 * assessment about how the measurement of this device is, the author change some of the behaviour
 * and add new functionalities and methods to carry out the aim of the project
 *
 * TODO: Pending add information  about the original lifevit parameters
 *
 * @param "nameFile"          This string corresponds with the name that will be saved in the internal storage
 *                            of the device and it must be in the following format "/datetime.txt"
 * @param "finalHRData"       List of the HR data gathered
 * @param "finalOXIMETERData" List of the SpO2 data gathered
 * @param "patientFile"       TXT file that will be stored in internal storage
 * @param "dataTimerHR"       Timer to control de measurement of HR data
 * @param "dataTimerOXI"      Timer to control de measurement of SpO2 data
 *
 * @author      Antoni Lopez
 * @author      Pau Ortega
 * @company     DyCare
 * @version     1.0 (DyCare)
 * @since       2.2.1 (lifevit)
 */
public class BraceletVitalActivity extends AppCompatActivity {

    private static final String TAG = BraceletVitalActivity.class.getSimpleName();

    TextView textview_connection_result, textview_info;
    Button button_connect, button_command;
    boolean isDisconnected = true;
    private LifevitSDKDeviceListener cl;

    //Patient information in order to complete the .txt result
    String nameFile ;

    ArrayList<String> finalHRData = new ArrayList<String>();
    ArrayList<String> finalOXIMETERData = new ArrayList<String>();

    FileWriter patientFile;

    Timer dataTimerHR = new Timer(false);
    Timer dataTimerOXI = new Timer(false);


    @Override
    /**
     * This callback, which is triggered when the system first creates the activity.
     * When the activity is created, it enters the Created state. In the onCreate() method,
     * you execute the basic start-up logic of the application which should occur only once in
     * the lifetime of the activity
     *
     * @throws IOException  If an input or output exception occurred
     * @author      Antoni Lopez
     * @author      Pau Ortega
     * @company     DyCare
     * @version     1.0 (DyCare)
     * @since       2.2.1 (lifevit)
     */
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_bracelet_vital);

        initComponents();
        initListeners();

    }

    @Override
    protected void onResume() {
        super.onResume();
        if (SDKTestApplication.getInstance().getLifevitSDKManager().isDeviceConnected(LifevitSDKConstants.DEVICE_BRACELET_VITAL)) {
            button_connect.setText("Disconnect");
            isDisconnected = false;
            textview_connection_result.setText("Connected");
            textview_connection_result.setTextColor(ContextCompat.getColor(BraceletVitalActivity.this, android.R.color.holo_green_dark));
        } else {
            button_connect.setText("Connect");
            isDisconnected = true;
            textview_connection_result.setText("Disconnected");
            textview_connection_result.setTextColor(ContextCompat.getColor(BraceletVitalActivity.this, android.R.color.holo_red_dark));
        }
        initSdk();
    }


    @Override
    protected void onPause() {
        super.onPause();
        SDKTestApplication.getInstance().getLifevitSDKManager().removeDeviceListener(cl);
        SDKTestApplication.getInstance().getLifevitSDKManager().setBraceletVitalListener(null);
    }


    private void initComponents() {
        textview_info = findViewById(R.id.bracelet_at2019_textview_command_info);
        textview_info.setMovementMethod(new ScrollingMovementMethod());
        textview_connection_result = findViewById(R.id.bracelet_at2019_connection_result);

        button_connect = findViewById(R.id.bracelet_at2019_connect);
        button_command = findViewById(R.id.bracelet_at2019_button_command);
    }


    private void initListeners() {

        button_connect.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (isDisconnected) {
                    SDKTestApplication.getInstance().getLifevitSDKManager().connectDevice(LifevitSDKConstants.DEVICE_BRACELET_VITAL, 60000, (String)"04:02:02:05:BF:13");
                } else {
                    SDKTestApplication.getInstance().getLifevitSDKManager().disconnectDevice(LifevitSDKConstants.DEVICE_BRACELET_VITAL);
                }
            }
        });

        button_command.setOnClickListener(new View.OnClickListener() {
            @Override
            /**
             * This onClick method will be called when "SEND COMMAND" button is clicked and show
             * all the functionalities that can be done in the next onClick method
             *<p>
             * What is new? Colors was implemented functionalities with 48 functionalities that
             * we reduced in order to manage easily the SDK app. The original number of the
             * functionalities was changed because we need to identify the specific button clicked.
             * <p>
             * @author      Antoni Lopez
             * @author      Pau Ortega
             * @company     DyCare
             * @version     1.0 (DyCare)
             * @since       2.2.1 (lifevit)
             */
            public void onClick(View view) {

                final LifevitSDKManager manager = SDKTestApplication.getInstance().getLifevitSDKManager();

                CharSequence[] colors = new CharSequence[]{
                        "0. Set device time (current time)",
                        "1. Get device time",
                        "2. Set user information",
                        "3. Get User information",
                        "4. Get MAC Address",
                        "5. Get Device Battery",
                        "6. Start HeartRate",
                        "7. Stop HeartRate",
                        "8. Start Blood Oxygen Test",
                        "9. Stop Blood Oxygen Test",
                };

                AlertDialog.Builder builder = new AlertDialog.Builder(BraceletVitalActivity.this);
                builder.setTitle("Select command");
                builder.setItems(colors, new DialogInterface.OnClickListener() {
                    @Override
                    /**
                     * This onClick method will be called when the functionality is chosen by the user
                     *<p>
                     * What is new? We deleted all the cases throw the switch-case that we won't need.
                     * Original cases 2,4,6,9, 12, 37 and 39 was not modified in terms of behaviour
                     * even though will be used in the assessment due to their functionality
                     * was correct only we change the number of the case that now they are
                     * but original cases 5,38 and 40 was modified to store all the previously and during
                     * measurements data gathered .
                     * <p>
                     * @author      Antoni Lopez
                     * @author      Pau Ortega
                     * @company     DyCare
                     * @version     1.0 (DyCare)
                     * @since       2.2.1 (lifevit)
                     */
                    public void onClick(DialogInterface dialog, int which) {
                        switch (which) {

                            case 0: {
                                Calendar cal = Calendar.getInstance();
                                manager.setBraceletDate(cal.getTime());
                                break;
                            }

                            case 1:
                                manager.getBraceletDate();
                                break;
                            case 2: {

                                Calendar cal = Calendar.getInstance();
                                nameFile = "/"+Calendar.getInstance().getTime()+".txt";

                                /**
                                 * Method creationFile() was created to initialize the name of
                                 * the file where we will store all the data obtained
                                 * nameFile will be equal to the adquisition time
                                 * @throws IOException  If an input or output exception occurred
                                 */
                                try {
                                    creationFile(nameFile);
                                } catch (IOException e) {
                                    throw new RuntimeException(e);
                                }

                                /**
                                 * Method write() of FileWriter class is used to write all the
                                 * information of the patient previously obtained. Method flush is used
                                 * to empty the stream.
                                 * @throws IOException  If an input or output exception occurred
                                 */
                                try {
                                    patientFile.write("Patient: " +nameFile+"\nDate: "+cal.getTime());

                                    patientFile.flush();
                                    //patientFile.close();
                                } catch (IOException e) {
                                    e.printStackTrace();
                                }

                            }
                            break;
                            case 3:
                                manager.getVitalUserInformation();
                                break;

                            case 4:
                                manager.getVitalMACAddress();
                                break;

                            case 5: {
                                manager.getBraceletBattery();
                                break;
                            }
                            case 6:
                                manager.startVitalHealthMeasurement(LifevitSDKConstants.BraceletVitalDataType.HR);
                                dataTimerHR.schedule(new TimerTask() {
                                    @Override
                                    public void run() {
                                        manager.startVitalHealthMeasurement(LifevitSDKConstants.BraceletVitalDataType.HR);
                                        dataTimerHR.schedule(new TimerTask() {
                                            @Override
                                            public void run() {
                                                manager.startVitalHealthMeasurement(LifevitSDKConstants.BraceletVitalDataType.HR);
                                            }
                                        }, 57000);
                                    }
                                }, 57000);

                                break;
                            /**
                             * Method write() of FileWriter class is used to write all the
                             * information of the patient previously obtained. Method flush is used
                             * to empty the stream.
                             * @throws IOException  If an input or output exception occurred
                             */
                            case 7:

                                manager.stopVitalHealthMeasurement(LifevitSDKConstants.BraceletVitalDataType.HR);
                                dataTimerHR.cancel();

                                try {
                                    patientFile.write("\nHeart_Rate_Data_Obtained:\n");
                                    patientFile.write(finalHRData.toString());
                                    patientFile.flush();
                                    //patientFile.close();
                                } catch (IOException e) {
                                    e.printStackTrace();
                                }

                                break;
                            case 8:
                                manager.startVitalHealthMeasurement(LifevitSDKConstants.BraceletVitalDataType.OXIMETER);
                                dataTimerOXI.schedule(new TimerTask() {
                                    @Override
                                    public void run() {
                                        manager.startVitalHealthMeasurement(LifevitSDKConstants.BraceletVitalDataType.OXIMETER);
                                        dataTimerOXI.schedule(new TimerTask() {
                                            @Override
                                            public void run() {
                                                manager.startVitalHealthMeasurement(LifevitSDKConstants.BraceletVitalDataType.OXIMETER);
                                            }
                                        }, 57000);
                                    }
                                }, 57000);
                                break;
                            /**
                             * Method write() of FileWriter class is used to write all the
                             * information of the patient previously obtained. Method flush is used
                             * to empty the stream.
                             * @throws IOException  If an input or output exception occurred
                             */
                            case 9:

                                manager.stopVitalHealthMeasurement(LifevitSDKConstants.BraceletVitalDataType.OXIMETER);
                                dataTimerOXI.cancel();

                                try {
                                    patientFile.write("\nSpO2_Data_Obtained:\n");
                                    patientFile.write(finalOXIMETERData.toString());
                                    patientFile.flush();
                                    //patientFile.close();
                                } catch (IOException e) {
                                    e.printStackTrace();
                                }

                                break;
                        }
                    }
                });
                builder.show();
            }
        });
    }

    private void initSdk() {

        // Create listener
        cl = new LifevitSDKDeviceListener() {

            @Override
            public void deviceOnConnectionError(int deviceType, final int errorCode) {
                if (deviceType != LifevitSDKConstants.DEVICE_BRACELET_VITAL) {
                    return;
                }
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        if (errorCode == LifevitSDKConstants.CODE_LOCATION_DISABLED) {
                            textview_connection_result.setText("ERROR: Debe activar permisos localización");
                        } else if (errorCode == LifevitSDKConstants.CODE_BLUETOOTH_DISABLED) {
                            textview_connection_result.setText("ERROR: El bluetooth no está activado");
                        } else if (errorCode == LifevitSDKConstants.CODE_LOCATION_TURN_OFF) {
                            textview_connection_result.setText("ERROR: La Ubicación está apagada");
                        } else {
                            textview_connection_result.setText("ERROR: Desconocido");
                        }
                    }
                });
            }

            @Override
            public void deviceOnConnectionChanged(int deviceType, final int status) {
                if (deviceType != LifevitSDKConstants.DEVICE_BRACELET_VITAL) {
                    return;
                }

                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        switch (status) {
                            case LifevitSDKConstants.STATUS_DISCONNECTED:
                                button_connect.setText("Connect");
                                isDisconnected = true;
                                textview_connection_result.setText("Disconnected");
                                textview_connection_result.setTextColor(ContextCompat.getColor(BraceletVitalActivity.this, android.R.color.holo_red_dark));
                                break;
                            case LifevitSDKConstants.STATUS_SCANNING:
                                button_connect.setText("Stop scan");
                                isDisconnected = false;
                                textview_connection_result.setText("Scanning");
                                textview_connection_result.setTextColor(ContextCompat.getColor(BraceletVitalActivity.this, android.R.color.holo_blue_dark));
                                break;
                            case LifevitSDKConstants.STATUS_CONNECTING:
                                button_connect.setText("Disconnect");
                                isDisconnected = false;
                                textview_connection_result.setText("Connecting");
                                textview_connection_result.setTextColor(ContextCompat.getColor(BraceletVitalActivity.this, android.R.color.holo_orange_dark));
                                break;
                            case LifevitSDKConstants.STATUS_CONNECTED:
                                button_connect.setText("Disconnect");
                                isDisconnected = false;
                                textview_connection_result.setText("Connected");
                                textview_connection_result.setTextColor(ContextCompat.getColor(BraceletVitalActivity.this, android.R.color.holo_green_dark));
                                break;
                        }
                    }
                });
            }
        };

        LifevitSDKBraceletVitalListener bListener = new LifevitSDKBraceletVitalListener() {

            @Override
            /**
             * This method was implement to print on the screen all the LifevitSDKResponse data
             * received by the vital device if the response is different to null
             *<p>
             * What is new? We created an object to store all this data sent and filter in order
             * to save the data in the correct ArrayList (finalHRData or finalOximeterData). Then,
             * when the data is filtered by type a string is created with the measurement time
             * (getDate()) and the HR measured (getHeartRate()) only separated by one space.
             * Finally, with method add() the new string is saved in the corresponding ArrayList
             * <p>
             *
             * @param "data"        Object to filter the response
             * @param "d"           "data" object casted to the corresponding format
             * @param "heartRate"   HR info that will be saved
             * @param "spo2"        SpO2 info that will be saved
             * @author      Antoni Lopez
             * @author      Pau Ortega
             * @company     DyCare
             * @version     1.0 (DyCare)
             * @since       2.2.1 (lifevit)
             */
            public void braceletVitalInformation(String device, final LifevitSDKResponse response) {
                synchronized (textview_info) {
                    runOnUiThread(new Runnable() {
                        @Override
                        public void run() {

                            if (response != null){

                                Object data = response.getData();

                                if(data instanceof LifevitSDKHeartbeatData){

                                    LifevitSDKHeartbeatData d = (LifevitSDKHeartbeatData) response.getData();
                                    String heartRate = d.getDate() + " " + d.getHeartRate();
                                    finalHRData.add(heartRate);

                                } else if (data instanceof LifevitSDKOximeterData) {

                                    LifevitSDKOximeterData d = (LifevitSDKOximeterData) response.getData();
                                    String spo2 = d.getDate() + " " + d.getSpO2();
                                    finalOXIMETERData.add(spo2);

                                }

                                String text = "";
                                text += "\n";
                                text += response.getCommand().toString();
                                text += "\n";
                                text += response.toString();
                                text += "\n\n";
                                text += textview_info.getText().toString();
                                textview_info.setText(text);

                            }
                        }
                    });
                }
            }

            @Override
            public void braceletVitalError(String device, final LifevitSDKConstants.BraceletVitalError error, LifevitSDKConstants.BraceletVitalCommand command) {
                synchronized (textview_info) {

                    runOnUiThread(new Runnable() {
                        @Override
                        public void run() {

                            if (error == LifevitSDKConstants.BraceletVitalError.ERROR_SENDING_COMMAND) {
                                String text = textview_info.getText().toString();
                                text += "\n";
                                text += "Wrong parameters.";
                                textview_info.setText(text);
                                Log.d(TAG, "[braceletError] " + text);
                            }
                        }
                    });
                }
            }

            @Override
            public void braceletVitalOperation(String device, final LifevitSDKConstants.BraceletVitalOperation operation) {
                synchronized (textview_info) {
                    runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            String text = textview_info.getText().toString();
                            text += "\n";
                            text += "Operation received: " + operation;
                            textview_info.setText(text);
                            Log.d(TAG, "[braceletOperation] " + text);
                        }
                    });
                }
            }

            @Override
            public void braceletVitalSOS(String device) {
                synchronized (textview_info) {
                    runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            String text = textview_info.getText().toString();
                            text += "\n";
                            text += "SOS received!";
                            textview_info.setText(text);
                            Log.d(TAG, "[braceletSOS] " + text);
                        }
                    });
                }
            }
        };

        // Create connection helper
        SDKTestApplication.getInstance().getLifevitSDKManager().addDeviceListener(cl);
        SDKTestApplication.getInstance().getLifevitSDKManager().setBraceletVitalListener(bListener);
    }

    /**
     * The creationFile method was done for the txt file creation. The path parameter create a new
     * file in the internal storage directory adding the name that is passed as a parameter.
     *<p>
     *
     * @throws IOException  If an input or output exception occurred
     * @param "path" the path name of the internal storage directory with the name of the new file
     * @author      Antoni Lopez
     * @author      Pau Ortega
     * @company     DyCare
     * @version     1.0 (DyCare)
     * @since       2.2.1 (lifevit)
     */
    private void creationFile(String name) throws IOException {
        File path = new File(Environment.getExternalStorageDirectory()+name);
        patientFile = new FileWriter(path,true);
    }

}
