using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif
public class LabelOverride : PropertyAttribute
{
    public string label;
    public LabelOverride ( string label )
    {
        this.label = label;
    }

    #if UNITY_EDITOR
    [CustomPropertyDrawer( typeof(LabelOverride) )]
    public class ThisPropertyDrawer : PropertyDrawer
    {
        public override void OnGUI ( Rect position , SerializedProperty property , GUIContent label )
        {
            try
            {
                var propertyAttribute = this.attribute as LabelOverride;
                if( IsItBloodyArrayTho( property ) == false )
                {
                    label.text = propertyAttribute.label;
                    
                } else
                {
                    Debug.LogWarningFormat(
                        "{0}(\"{1}\") doesn't support arrays ",
                        typeof(LabelOverride).Name ,
                        propertyAttribute.label
                    );
                }
                EditorGUI.PropertyField( position , property , label );
            } catch ( System.Exception ex )
            {
                if(ex.GetType() != typeof(ExitGUIException))
                    Debug.LogException( ex );
            }
        }
        
        bool IsItBloodyArrayTho ( SerializedProperty property  )
        {
            string path =  property.propertyPath;
            int idot = path.IndexOf('.');
            if( idot==-1 ) return false;
            string propName = path.Substring( 0 , idot );
            SerializedProperty p = property.serializedObject.FindProperty( propName );
            return p.isArray;
            //CREDITS: https://answers.unity.com/questions/603882/serializedproperty-isnt-being-detected-as-an-array.html
        }
    }
    #endif
}